//
//  ContentView.swift
//  Dead Simple Budget
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var store = BudgetStore()
    @StateObject private var premiumManager = PremiumManager()
    @StateObject private var incomeForm = IncomeFormState()
    @StateObject private var billsForm = BillsFormState()
    @StateObject private var savingsForm = SavingsFormState()
    @AppStorage(CurrencyHelper.currencyOptionKey) private var currencyLocaleId: String = ""
    @State private var optionsExpanded = false
    @State private var showIncomeSheet = false
    @State private var showBillsSheet = false
    @State private var showSavingsSheet = false
    @State private var showPaywall = false
    @State private var showUpgradePrompt = false
    @State private var upgradePromptLaunchCount = 0
    @State private var payText: String = ""
    @State private var billsText: String = ""
    /// When true, we're updating payText/billsText from store; skip applying those changes back to store.
    @State private var syncingSummaryFromStore = false

    var body: some View {
        let _ = CurrencyHelper.applySavedLocale(identifier: currencyLocaleId.isEmpty ? nil : currencyLocaleId)
        return ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 16)
                    monthlySummary
                    Spacer(minLength: 24)
                    safeDailySpendBlock
                    Spacer(minLength: 24)
                    ZStack {
                        Image("BackgroundImage")
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    Spacer(minLength: 48)
                    optionalAdjustments
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showIncomeSheet) { incomeSheet }
        .sheet(isPresented: $showBillsSheet) { billsSheet }
        .sheet(isPresented: $showSavingsSheet) { savingsSheet }
        .sheet(isPresented: $showPaywall) {
            PaywallView(manager: premiumManager, isPresented: $showPaywall)
        }
        .onAppear {
            // Wait for StoreKit entitlements; onAppear runs before PremiumManager’s async refresh() finishes,
            // so checking isPremium here can wrongly show the upgrade prompt to subscribers.
            Task {
                await premiumManager.refresh()
                checkUpgradePromptAfterLaunch()
            }
            pushWidgetData()
            handleNotifications()
        }
        .onChange(of: store.safeDailySpend) { _, _ in
            pushWidgetData()
        }
        .onChange(of: store.remainingThisMonth) { _, _ in
            pushWidgetData()
        }
        .onChange(of: premiumManager.isPremium) { _, isPremium in
            if isPremium { showUpgradePrompt = false }
            pushWidgetData()
            handleNotifications()
        }
        .onChange(of: currencyLocaleId) { _, _ in
            pushWidgetData()
        }
        .sheet(isPresented: $showUpgradePrompt) {
            upgradePromptSheet
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .fontWeight(.medium)
                .foregroundStyle(DSBTheme.emerald)
            }
        }
    }

    private var upgradePromptSheet: some View {
        VStack(spacing: 24) {
            Text("Upgrade to unlock unlimited use")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            Text("You've used your \(upgradePromptLaunchCount) free app opens. Upgrade to unlock the widget and all features.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            VStack(spacing: 12) {
                Button {
                    showUpgradePrompt = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showPaywall = true
                    }
                } label: {
                    ZStack {
                        Color.clear
                        Text("Upgrade")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
                    .background { AdaptiveMetalButton(selected: true, cornerRadius: DSBTheme.cornerRadiusButton).clipShape(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusButton)) }
                    .foregroundStyle(.white)
                    .overlay(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusButton).stroke(DSBTheme.metalStroke(isSelected: true, colorScheme: colorScheme), lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button {
                    showUpgradePrompt = false
                } label: {
                    ZStack {
                        Color.clear
                        Text("Maybe later")
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
                    .background { AdaptiveMetalButton(selected: false, cornerRadius: DSBTheme.cornerRadiusButton).clipShape(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusButton)) }
                    .overlay(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusButton).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationDetents([.medium])
    }

    private func handleNotifications() {
        if premiumManager.isPremium {
            BudgetNotificationManager.requestAndScheduleWeeklyIfNeeded(
                safeDailySpend: store.safeDailySpend,
                remainingThisMonth: store.remainingThisMonth
            )
        } else {
            BudgetNotificationManager.cancelWeekly()
        }
    }

    private static let launchCountKey = "dsb.freeLaunchCount"
    private static let lastUpgradePromptDateKey = "dsb.lastUpgradePromptDate"
    private static let upgradePromptThreshold = 5
    private static let upgradePromptCooldownHours: TimeInterval = 24

    private func checkUpgradePromptAfterLaunch() {
        guard !premiumManager.isPremium else { return }
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: Self.launchCountKey)
        let newCount = count + 1
        defaults.set(newCount, forKey: Self.launchCountKey)
        guard newCount >= Self.upgradePromptThreshold else { return }
        let lastPrompt = defaults.object(forKey: Self.lastUpgradePromptDateKey) as? Date
        let now = Date()
        if let last = lastPrompt, now.timeIntervalSince(last) < Self.upgradePromptCooldownHours * 3600 {
            return
        }
        defaults.set(now, forKey: Self.lastUpgradePromptDateKey)
        upgradePromptLaunchCount = newCount
        showUpgradePrompt = true
    }

    private var header: some View {
        Text("Dead Simple Budget")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 16)
    }

    private var monthlySummary: some View {
        monthlySummaryContent
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background { AdaptiveMetalCard(cornerRadius: DSBTheme.cornerRadiusCard).clipShape(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusCard)) }
            .overlay(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusCard).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
            .onAppear { syncMonthlySummaryFromStore() }
            .onChange(of: payText) { _, new in
                guard !syncingSummaryFromStore else { return }
                applyPayTextChange(new)
            }
            .onChange(of: billsText) { _, new in
                guard !syncingSummaryFromStore else { return }
                applyBillsTextChange(new)
            }
            .onChange(of: store.monthlyIncome) { _, new in syncPayText(from: new) }
            .onChange(of: store.totalBills) { _, new in syncBillsText(from: new) }
            .onChange(of: store.lumpSumBills) { _, new in
                guard store.itemizedBills.isEmpty else { return }
                syncingSummaryFromStore = true
                billsText = new > 0 ? CurrencyHelper.formatIntegerWithGrouping(new) : ""
                DispatchQueue.main.async { syncingSummaryFromStore = false }
            }
    }

    private var monthlySummaryContent: some View {
        HStack(spacing: 16) {
            monthlySummaryColumn(
                titleLine1: "Take-home",
                titleLine2: "pay",
                text: $payText
            )
            monthlySummaryColumn(
                titleLine1: "Monthly",
                titleLine2: "bills",
                text: $billsText
            )
        }
    }

    private func monthlySummaryColumn(titleLine1: String, titleLine2: String, text: Binding<String>) -> some View {
        VStack(spacing: 6) {
            Text(titleLine1)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            Text(titleLine2)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.primary)
            HStack(spacing: 2) {
                Text(CurrencyHelper.currencySymbol)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.primary)
                TextField("0", text: text)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func syncMonthlySummaryFromStore() {
        syncingSummaryFromStore = true
        payText = store.monthlyIncome > 0 ? CurrencyHelper.formatIntegerWithGrouping(store.monthlyIncome) : ""
        billsText = store.totalBills > 0 ? CurrencyHelper.formatIntegerWithGrouping(store.totalBills) : ""
        DispatchQueue.main.async { syncingSummaryFromStore = false }
    }

    private func applyPayTextChange(_ new: String) {
        guard let v = CurrencyHelper.parseAmountFromString(new) else { return }
        store.setMonthlyIncomeFromSimple(v)
        store.save()
        payText = v > 0 ? CurrencyHelper.formatIntegerWithGrouping(v) : ""
    }

    private func applyBillsTextChange(_ new: String) {
        guard let v = CurrencyHelper.parseAmountFromString(new) else { return }
        store.lumpSumBills = v
        if !store.itemizedBills.isEmpty {
            store.itemizedBills = []
        }
        store.save()
        billsText = v > 0 ? CurrencyHelper.formatIntegerWithGrouping(v) : ""
    }

    private func syncPayText(from new: Double) {
        let current = CurrencyHelper.parseAmountFromString(payText) ?? 0
        if payText.isEmpty || abs(current - new) > 0.01 {
            syncingSummaryFromStore = true
            payText = new > 0 ? CurrencyHelper.formatIntegerWithGrouping(new) : ""
            DispatchQueue.main.async { syncingSummaryFromStore = false }
        }
    }

    private func syncBillsText(from new: Double) {
        let current = CurrencyHelper.parseAmountFromString(billsText) ?? 0
        if billsText.isEmpty || abs(current - new) > 0.01 {
            syncingSummaryFromStore = true
            billsText = new > 0 ? CurrencyHelper.formatIntegerWithGrouping(new) : ""
            DispatchQueue.main.async { syncingSummaryFromStore = false }
        }
    }

    private var safeDailySpendBlock: some View {
        VStack(spacing: 6) {
            Text("Safe Daily Spend")
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                let daily = store.safeDailySpend.isFinite ? store.safeDailySpend : 0
                Text(CurrencyHelper.format(daily))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(daily < 0 ? Color.red : DSBTheme.emerald)
                Text("per day")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            let remaining = store.remainingThisMonth
            HStack(spacing: 4) {
                Text("Total left this month:")
                    .font(.subheadline)
                    .foregroundStyle(remaining < 0 ? .red : .secondary)
                Text(CurrencyHelper.format(remaining.isFinite ? remaining : 0))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(remaining < 0 ? .red : .primary)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background { AdaptiveMetalCard(cornerRadius: DSBTheme.cornerRadiusCard).clipShape(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusCard)) }
        .overlay(RoundedRectangle(cornerRadius: DSBTheme.cornerRadiusCard).stroke(DSBTheme.metalStroke(isSelected: false, colorScheme: colorScheme), lineWidth: 1))
        .contentTransition(.numericText())
        .animation(.easeInOut(duration: 0.25), value: store.safeDailySpend)
    }

    private var optionalAdjustments: some View {
        OptionalAdjustmentsView(
            isExpanded: $optionsExpanded,
            isPremium: premiumManager.isPremium,
            monthlyIncome: store.monthlyIncome,
            totalBills: store.totalBills,
            savingsMonthlyEquivalent: premiumManager.isPremium ? store.savingsMonthlyEquivalent : 0,
            savingsEnabled: Binding(
                get: {
                    premiumManager.isPremium ? store.savingsEnabled : false
                },
                set: { newValue in
                    if premiumManager.isPremium {
                        store.savingsEnabled = newValue
                        store.save()
                    } else {
                        showPaywall = true
                    }
                }
            ),
            onSaveSavings: { store.save() },
            onEditPaycheck: {
                if premiumManager.isPremium { showIncomeSheet = true }
                else { showPaywall = true }
            },
            onEditBills: {
                if premiumManager.isPremium { showBillsSheet = true }
                else { showPaywall = true }
            },
            onEditSavings: {
                if premiumManager.isPremium { showSavingsSheet = true }
                else { showPaywall = true }
            },
            onRequestPremium: { showPaywall = true },
            currencyLocaleId: $currencyLocaleId
        )
    }

    private var incomeSheet: some View {
        NavigationStack {
            IncomeEditView(form: incomeForm, onSave: {
                incomeForm.applyTo(store)
                showIncomeSheet = false
            })
            .navigationTitle("Take-home pay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        incomeForm.applyTo(store)
                        showIncomeSheet = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(DSBTheme.emerald)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showIncomeSheet = false }
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear { incomeForm.syncFrom(store) }
        }
    }

    private var billsSheet: some View {
        NavigationStack {
            BillsEditView(
                form: billsForm,
                defaultBillsAmount: BudgetStore.defaultBills,
                onUseDefault: {
                    store.lumpSumBills = BudgetStore.defaultBills
                    store.itemizedBills = []
                    store.save()
                    showBillsSheet = false
                },
                onSave: {
                    billsForm.applyTo(store)
                    showBillsSheet = false
                }
            )
            .navigationTitle("My bills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        billsForm.applyTo(store)
                        showBillsSheet = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(DSBTheme.emerald)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showBillsSheet = false }
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear { billsForm.syncFrom(store) }
        }
    }

    private var savingsSheet: some View {
        NavigationStack {
            SavingsEditView(form: savingsForm, onSave: {
                savingsForm.applyTo(store)
                showSavingsSheet = false
            })
            .navigationTitle("Savings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savingsForm.applyTo(store)
                        showSavingsSheet = false
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(DSBTheme.emerald)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSavingsSheet = false }
                        .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                savingsForm.syncFrom(store)
            }
        }
    }

    private func pushWidgetData() {
        let monthly = store.monthlySpendable.isFinite ? store.monthlySpendable : 0
        let daily = store.safeDailySpend.isFinite ? store.safeDailySpend : 0
        let remaining = store.remainingThisMonth.isFinite ? store.remainingThisMonth : 0
        WidgetSharedData.update(
            monthlySpendable: monthly,
            formattedSafeDaily: CurrencyHelper.format(daily),
            formattedRemaining: CurrencyHelper.format(remaining),
            currencyLocaleIdentifier: currencyLocaleId,
            isPremium: premiumManager.isPremium
        )
    }

}

#Preview {
    ContentView()
}
