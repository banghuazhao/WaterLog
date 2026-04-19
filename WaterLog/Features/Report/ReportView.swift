//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Charts
import SwiftUI

struct ReportView: View {
    @Bindable var reportViewModel: ReportViewModel
    private var appModel: AppModel { reportViewModel.appModel }
    private var unit: VolumeUnit { appModel.appSettings.unit }

    @State private var selectedVolumeDay: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WaterLogTheme.contentStackSpacing) {
                    controls
                    summaryCard
                    volumeAndBreakdownCard
                    mixChartCard
                    hourlyChartCard
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .scrollContentBackground(.hidden)
            .background {
                WaterLogTheme.secondaryScreenBackground.ignoresSafeArea()
            }
            .navigationTitle("Report")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            export()
                        } label: {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $reportViewModel.activeDetail, onDismiss: {
                selectedVolumeDay = nil
            }) { route in
                switch route {
                case let .calendarDay(day):
                    ReportDayDetailView(dayStart: day, appModel: appModel)
                        .presentationDetents([.medium, .large])
                case let .drinkType(type):
                    ReportDrinkTypeDetailView(
                        drinkType: type,
                        window: reportViewModel.window,
                        anchor: reportViewModel.anchorDate,
                        appModel: appModel
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .sheet(item: $reportViewModel.exportDocument) { doc in
                ActivityView(items: [doc.url])
            }
        }
    }

    private var controls: some View {
        WLReportCard(
            title: "Time range",
            subtitle: "Switch day, week, or month, then step through periods."
        ) {
            VStack(spacing: 12) {
                Picker("Range", selection: $reportViewModel.window) {
                    ForEach(AppModel.ReportWindow.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    reportNavButton(systemName: "chevron.left") {
                        reportViewModel.shiftAnchor(-1)
                    }
                    Spacer(minLength: 8)
                    Text(periodTitle)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    reportNavButton(systemName: "chevron.right") {
                        reportViewModel.shiftAnchor(1)
                    }
                }
            }
        }
    }

    private func reportNavButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .overlay {
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(WaterLogTheme.accent)
    }

    private var periodTitle: String {
        let cal = Calendar.current
        let anchor = reportViewModel.anchorDate
        switch reportViewModel.window {
        case .day:
            return anchor.formatted(date: .complete, time: .omitted)
        case .week:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: anchor))!
            let end = cal.date(byAdding: .day, value: 6, to: start)!
            return "\(start.formatted(.dateTime.month().day())) – \(end.formatted(.dateTime.month().day().year()))"
        case .month:
            return anchor.formatted(.dateTime.month(.wide).year())
        }
    }

    private var summaryCard: some View {
        let goal = appModel.appSettings.dailyGoalMl
        let dayBuckets = reportViewModel.dayTotals.count
        return WLReportCard(title: "Overview", subtitle: nil) {
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                statCell(
                    title: "Total",
                    value: VolumeFormatting.format(ml: reportViewModel.totalVolumeMl, unit: unit)
                )
                statCell(
                    title: dayBuckets > 1 ? "Daily average" : "Volume",
                    value: VolumeFormatting.format(ml: reportViewModel.averagePerDayMl, unit: unit)
                )
                if dayBuckets > 1, goal > 0 {
                    statCell(
                        title: "Goal met",
                        value: "\(reportViewModel.daysMeetingGoal) / \(dayBuckets) days"
                    )
                }
                statCell(
                    title: "Entries",
                    value: "\(appModel.logs(in: reportViewModel.window, anchor: reportViewModel.anchorDate).count)"
                )
            }
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusSmall, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: WaterLogTheme.cornerRadiusSmall, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                }
        }
    }

    private var volumeAndBreakdownCard: some View {
        WLReportCard(
            title: "Volume by day",
            subtitle: "Tap the chart or a row below to open details."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if reportViewModel.dayTotals.allSatisfy({ $0.totalMl == 0 }) {
                    ContentUnavailableView(
                        "No data",
                        systemImage: "chart.bar",
                        description: Text("Log drinks to see this chart fill in.")
                    )
                    .frame(height: 200)
                } else {
                    Chart(reportViewModel.dayTotals) { row in
                        BarMark(
                            x: .value("Day", row.dayStart, unit: .day),
                            y: .value("ml", row.totalMl)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    WaterLogTheme.accent.opacity(0.45),
                                    WaterLogTheme.accent,
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    }
                    .chartXSelection(value: $selectedVolumeDay)
                    .chartYAxisLabel(VolumeUnit.metric.shortLabel)
                    .frame(height: 220)
                    .onChange(of: selectedVolumeDay) { _, new in
                        if let new {
                            let day = Calendar.current.startOfDay(for: new)
                            reportViewModel.activeDetail = .calendarDay(day)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily breakdown")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(reportViewModel.dayTotals.filter { $0.totalMl > 0 }) { day in
                            Button {
                                reportViewModel.activeDetail = .calendarDay(day.dayStart)
                            } label: {
                                HStack {
                                    Text(day.dayStart.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(VolumeFormatting.format(ml: day.totalMl, unit: unit))
                                        .font(.subheadline.monospacedDigit().weight(.semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var mixChartCard: some View {
        WLReportCard(
            title: "Drink mix",
            subtitle: "Tap a drink in the list to see entries in this period."
        ) {
            let rows = reportViewModel.drinkBreakdown
            if rows.isEmpty {
                ContentUnavailableView("No mix yet", systemImage: "chart.pie", description: Text("Variety will show up here."))
                    .frame(height: 220)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Chart {
                        ForEach(rows, id: \.0.id) { row in
                            SectorMark(
                                angle: .value("Volume", row.1),
                                innerRadius: .ratio(0.55),
                                angularInset: 1.5
                            )
                            .foregroundStyle(Color(hex: row.0.tintHex))
                            .opacity(0.9)
                        }
                    }
                    .frame(height: 220)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(rows, id: \.0.id) { row in
                            Button {
                                reportViewModel.activeDetail = .drinkType(row.0)
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: row.0.tintHex))
                                        .frame(width: 10, height: 10)
                                    Text(row.0.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(VolumeFormatting.format(ml: row.1, unit: unit))
                                        .font(.footnote.monospacedDigit().weight(.medium))
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .font(.footnote)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var hourlyChartCard: some View {
        let buckets = reportViewModel.hourlyBuckets.filter { $0.ml >= 0.5 }
        return WLReportCard(
            title: "Time of day",
            subtitle: "When you tend to log drinks in this period (by hour)."
        ) {
            if buckets.isEmpty {
                ContentUnavailableView(
                    "No hourly data",
                    systemImage: "clock",
                    description: Text("Volume by hour appears once you log drinks here.")
                )
                .frame(height: 160)
            } else {
                Chart(buckets, id: \.hour) { row in
                    BarMark(
                        x: .value("Hour", hourLabel(row.hour)),
                        y: .value("ml", row.ml)
                    )
                    .foregroundStyle(WaterLogTheme.accent.gradient)
                    .cornerRadius(4)
                }
                .chartYAxisLabel(VolumeUnit.metric.shortLabel)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6))
                }
                .frame(height: 200)
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        var cal = Calendar.current
        cal.timeZone = .current
        var c = DateComponents()
        c.hour = hour
        c.minute = 0
        let d = cal.date(from: c) ?? Date()
        return d.formatted(date: .omitted, time: .shortened)
    }

    private func export() {
        do {
            try reportViewModel.prepareExport()
        } catch {
            appModel.presentError(error)
        }
    }
}

extension ReportViewModel {
    func shiftAnchor(_ delta: Int) {
        let cal = Calendar.current
        switch window {
        case .day:
            anchorDate = cal.date(byAdding: .day, value: delta, to: anchorDate) ?? anchorDate
        case .week:
            anchorDate = cal.date(byAdding: .weekOfYear, value: delta, to: anchorDate) ?? anchorDate
        case .month:
            anchorDate = cal.date(byAdding: .month, value: delta, to: anchorDate) ?? anchorDate
        }
    }
}
