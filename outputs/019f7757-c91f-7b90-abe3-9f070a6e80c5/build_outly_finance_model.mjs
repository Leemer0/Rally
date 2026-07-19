import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "/Users/liam/Repos/Rally/outputs/019f7757-c91f-7b90-abe3-9f070a6e80c5";
await fs.mkdir(outputDir, { recursive: true });

const workbook = Workbook.create();
const summary = workbook.worksheets.add("Summary");
const pilot = workbook.worksheets.add("Toronto Pilot");
const assumptions = workbook.worksheets.add("Assumptions");
const unit = workbook.worksheets.add("Unit Economics");
const scenarios = workbook.worksheets.add("Scenarios");
const checks = workbook.worksheets.add("Checks");
const sources = workbook.worksheets.add("Sources");

const C = {
  ink: "#0B0D0E",
  charcoal: "#171A1C",
  lime: "#C7FF3D",
  limeSoft: "#EDFFC1",
  silver: "#E7EAEC",
  line: "#CBD1D5",
  paper: "#F7F8F8",
  white: "#FFFFFF",
  blue: "#0000FF",
  green: "#008000",
  red: "#D92D20",
  yellow: "#FFF4B8",
  muted: "#5F686E",
};

const money = '"C$"#,##0;[Red]("C$"#,##0);-';
const money1 = '"C$"#,##0.0;[Red]("C$"#,##0.0);-';
const pct = '0.0%;[Red](0.0%);-';
const countFmt = '#,##0;[Red](#,##0);-';
const usd = '"US$"#,##0.00;[Red]("US$"#,##0.00);-';

function title(sheet, range, text) {
  const r = sheet.getRange(range);
  r.merge();
  r.values = [[text]];
  r.format = {
    fill: C.ink,
    font: { color: C.white, bold: true, size: 20 },
    verticalAlignment: "center",
  };
  r.format.rowHeight = 34;
}

function section(sheet, range, text) {
  const r = sheet.getRange(range);
  r.merge();
  r.values = [[text]];
  r.format = {
    fill: C.charcoal,
    font: { color: C.white, bold: true, size: 11 },
    verticalAlignment: "center",
  };
  r.format.rowHeight = 22;
}

function headers(sheet, range) {
  sheet.getRange(range).format = {
    fill: C.silver,
    font: { color: C.ink, bold: true },
    borders: { bottom: { style: "thin", color: C.ink } },
    verticalAlignment: "center",
    wrapText: true,
  };
}

function inputStyle(sheet, range) {
  sheet.getRange(range).format = {
    fill: C.yellow,
    font: { color: C.blue },
  };
}

function formulaStyle(sheet, range, linked = false) {
  sheet.getRange(range).format.font = { color: linked ? C.green : C.ink };
}

function noteStyle(sheet, range) {
  sheet.getRange(range).format = {
    fill: C.paper,
    font: { color: C.muted, italic: true, size: 9 },
    wrapText: true,
  };
}

for (const sheet of [summary, pilot, assumptions, unit, scenarios, checks, sources]) {
  sheet.showGridLines = false;
}

// Assumptions
title(assumptions, "A1:F1", "OUTLY — Revenue & Profit Model Assumptions");
assumptions.getRange("A2:F2").values = [["Version", "1.2", "Currency", "CAD", "As of", "2026-07-18"]];
assumptions.getRange("A2:F2").format = { font: { color: C.muted, size: 9 } };
assumptions.getRange("A4:F4").values = [["Legend", "Editable input", "Formula", "Cross-sheet link", "Source/estimate", "All prices exclude HST"]];
assumptions.getRange("B4").format = { fill: C.yellow, font: { color: C.blue } };
assumptions.getRange("C4").format.font = { color: C.ink };
assumptions.getRange("D4").format.font = { color: C.green };
assumptions.getRange("E4").format.font = { color: C.muted, italic: true };
assumptions.getRange("A4:F4").format.borders = { bottom: { style: "thin", color: C.line } };

section(assumptions, "A6:F6", "Venue subscription pricing");
assumptions.getRange("A7:F7").values = [["Driver", "Free", "Paid", "Unit", "Source type", "Notes"]];
headers(assumptions, "A7:F7");
assumptions.getRange("A8:F17").values = [
  ["Monthly list price", 0, 199, "CAD / month", "Outly recommendation", "Free listing and one paid membership"],
  ["Annual list price", 0, 1990, "CAD / year", "Outly recommendation", "Paid plan equals two months free annually"],
  ["Listed venue mix", 0.6, 0.4, "% of listed venues", "Model assumption", "Free and paid mix must total 100%"],
  ["Support hours", 0.1, 0.75, "hours / month", "Model assumption", "Light listing support vs paid reporting"],
  ["Support hourly cost", 40, 40, "CAD / hour", "Model assumption", "Fully loaded contractor/ops rate"],
  ["Variable technology cost", 1, 4, "CAD / month", "Model assumption", "Free listing record vs paid analytics and brand-partner reporting"],
  ["Stripe Payments rate", 0, 0.029, "% of payment", "Stripe Canada", "Only the paid membership is processed"],
  ["Stripe fixed fee", 0, 0.3, "CAD / transaction", "Stripe Canada", "Only the paid membership is processed"],
  ["Stripe Billing rate", 0, 0.007, "% of billing volume", "Stripe Canada", "Only the paid membership is processed"],
  ["Annual-plan share", 0, 0.4, "% of venues", "Model assumption", "Paid members blend monthly and annual pricing"],
];
inputStyle(assumptions, "B8:C17");
assumptions.getRange("B8:C9").format.numberFormat = money;
assumptions.getRange("B10:C10").format.numberFormat = pct;
assumptions.getRange("B11:C11").format.numberFormat = "0.00";
assumptions.getRange("B12:C13").format.numberFormat = money;
assumptions.getRange("B14:C14").format.numberFormat = pct;
assumptions.getRange("B15:C15").format.numberFormat = money1;
assumptions.getRange("B16:C17").format.numberFormat = pct;

section(assumptions, "A19:F19", "Brand partner pricing — sponsored bar nights");
assumptions.getRange("A20:D20").values = [["Driver", "Value", "Unit", "Notes"]];
headers(assumptions, "A20:D20");
assumptions.getRange("A21:D31").values = [
  ["One-night sponsored activation fee", 3000, "CAD / matched bar night", "Flat Outly fee; no setup or per-visit charge"],
  ["Three-night bundle price", 7500, "CAD / 3-night bundle", "C$2,500 per night; approximately 17% bundle discount"],
  ["Six-night bundle price", 13500, "CAD / 6-night bundle", "C$2,250 per night; 25% bundle discount"],
  ["Expected app location check-ins", 150, "check-ins / sponsored night", "Reporting estimate only; does not determine advertiser price"],
  ["Per-check-in advertiser charge", 0, "CAD / app check-in", "No usage-based attendance charge"],
  ["Bars matched per sponsored night", 1, "bars / sponsored night", "One brand partner is connected with one demographic-fit bar"],
  ["Advertiser-funded offer budget", 2000, "CAD / sponsored night", "Pass-through; excluded from Outly net revenue"],
  ["Activation operations hours", 8, "hours / sponsored night", "Partner management, venue coordination and reporting"],
  ["Operations hourly cost", 40, "CAD / hour", "Fully loaded contractor/ops rate"],
  ["Creative and delivery cost", 350, "CAD / sponsored night", "Design, QA and activation tooling"],
  ["Reward management fee", 0.2, "% of reward budget", "Optional fee for managing advertiser-funded consumer offers"],
];
inputStyle(assumptions, "B21:B31");
assumptions.getRange("B21:B23").format.numberFormat = money;
assumptions.getRange("B24").format.numberFormat = countFmt;
assumptions.getRange("B25").format.numberFormat = money;
assumptions.getRange("B26").format.numberFormat = countFmt;
assumptions.getRange("B27").format.numberFormat = money;
assumptions.getRange("B28:B29").format.numberFormat = "0.0";
assumptions.getRange("B30").format.numberFormat = money;
assumptions.getRange("B31").format.numberFormat = pct;

section(assumptions, "A33:F33", "Base-case scale and operating investment");
assumptions.getRange("A34:D34").values = [["Driver", "Value", "Unit", "Notes"]];
headers(assumptions, "A34:D34");
assumptions.getRange("A35:D40").values = [
  ["Base listed venues", 50, "venues", "Used for per-venue fixed platform allocation"],
  ["Base sponsored nights per month", 2, "sponsored nights", "Each night pairs one brand partner with one matched bar"],
  ["Founder / contractor compensation", 5000, "CAD / month", "Editable cash operating cost"],
  ["Sales and marketing", 2000, "CAD / month", "Venue acquisition and consumer growth"],
  ["Legal and accounting", 500, "CAD / month", "Budget reserve"],
  ["Other G&A", 200, "CAD / month", "Insurance, travel and misc."],
];
inputStyle(assumptions, "B35:B40");
assumptions.getRange("B35:B36").format.numberFormat = countFmt;
assumptions.getRange("B37:B40").format.numberFormat = money;

section(assumptions, "A42:F42", "Fixed production platform costs");
assumptions.getRange("A43:F43").values = [["Service", "Vendor price", "Currency", "Billing", "Monthly CAD", "Notes"]];
headers(assumptions, "A43:F43");
assumptions.getRange("A44:D55").values = [
  ["Supabase Pro", 25, "USD", "Monthly"],
  ["Vercel Pro", 20, "USD", "Monthly"],
  ["Sentry Team", 26, "USD", "Monthly, annual commitment"],
  ["Resend Pro", 20, "USD", "Monthly"],
  ["Apple Developer Program", 99, "USD", "Annual"],
  ["PostHog", 0, "USD", "Within free tier"],
  ["Mapbox Mobile Maps", 0, "USD", "Within 25k MAU free tier"],
  ["Xcode Cloud", 0, "USD", "25 hours included"],
  ["GoDaddy domain + included email", 5, "CAD", "Monthly equivalent estimate"],
  ["QuickBooks Online", 40, "CAD", "Monthly estimate"],
  ["1Password", 20, "CAD", "Monthly estimate"],
  ["Platform contingency", 100, "CAD", "Monthly reserve"],
];
inputStyle(assumptions, "B44:B55");
assumptions.getRange("B44:B55").format.numberFormat = money1;
assumptions.getRange("E44:E55").formulas = Array.from({ length: 12 }, (_, i) => {
  const row = 44 + i;
  return [`=IF(C${row}="USD",IF(D${row}="Annual",B${row}/12*$B$59,B${row}*$B$59),B${row})`];
});
formulaStyle(assumptions, "E44:E55");
assumptions.getRange("E44:E55").format.numberFormat = money1;
assumptions.getRange("A56:D56").values = [["Total fixed platform cost", null, null, null]];
assumptions.getRange("E56").formulas = [["=SUM(E44:E55)"]];
assumptions.getRange("A56:E56").format = {
  font: { bold: true, color: C.ink },
  borders: { top: { style: "thin", color: C.ink } },
};
assumptions.getRange("E56").format.numberFormat = money;

section(assumptions, "A58:F58", "Global assumptions");
assumptions.getRange("A59:D62").values = [
  ["USD / CAD conversion", 1.42, "CAD per USD", "Rounded planning rate; update as needed"],
  ["HST", 0.13, "%", "Excluded from revenue and profit because it is remitted"],
  ["Model basis", "Monthly", "", "Revenue and expenses shown before income tax"],
  ["Pricing posture", "Toronto pilot first", "", "Validate C$129 pilot pricing before standard launch tiers"],
];
inputStyle(assumptions, "B59:B60");
assumptions.getRange("B59").format.numberFormat = "0.00";
assumptions.getRange("B60").format.numberFormat = pct;
noteStyle(assumptions, "A64:F66");
assumptions.getRange("A64:F66").merge();
assumptions.getRange("A64:F66").values = [["Model convention: advertiser-funded rewards are treated as pass-through cash and excluded from Outly net revenue and direct cost. Confirm final accounting treatment with an accountant. Pricing excludes HST and income tax."]];

// Unit economics
title(unit, "A1:L1", "OUTLY — Unit Economics");
unit.getRange("A2:L2").values = [["Editable assumptions are on the Assumptions tab. Free listings carry a small service cost; the single paid membership generates subscription contribution. Fixed corporate costs are handled separately.", null, null, null, null, null, null, null, null, null, null, null]];
noteStyle(unit, "A2:L2");
unit.getRange("A2:L2").merge();
section(unit, "A4:L4", "Venue subscriptions — monthly unit economics");
unit.getRange("A5:L5").values = [["Plan", "Monthly list", "Annual list", "Realized monthly", "Support cost", "Tech cost", "Stripe fees", "Direct cost", "Contribution", "Contribution margin", "Allocated platform", "Profit after platform"]];
headers(unit, "A5:L5");
unit.getRange("A6:A8").values = [["Free listing"], ["Paid membership"], ["Blended listed venue"]];
unit.getRange("B6:C7").formulas = [
  ["='Assumptions'!B8", "='Assumptions'!B9"],
  ["='Assumptions'!C8", "='Assumptions'!C9"],
];
unit.getRange("D6:D7").formulas = [
  ["=B6*(1-'Assumptions'!B17)+(C6/12)*'Assumptions'!B17"],
  ["=B7*(1-'Assumptions'!C17)+(C7/12)*'Assumptions'!C17"],
];
unit.getRange("E6:E7").formulas = [
  ["='Assumptions'!B11*'Assumptions'!B12"],
  ["='Assumptions'!C11*'Assumptions'!C12"],
];
unit.getRange("F6:F7").formulas = [["='Assumptions'!B13"], ["='Assumptions'!C13"]];
unit.getRange("G6:G7").formulas = [
  ["=D6*('Assumptions'!B14+'Assumptions'!B16)+'Assumptions'!B15"],
  ["=D7*('Assumptions'!C14+'Assumptions'!C16)+'Assumptions'!C15"],
];
unit.getRange("H6:H7").formulas = [["=SUM(E6:G6)"], ["=SUM(E7:G7)"]];
unit.getRange("I6:I7").formulas = [["=D6-H6"], ["=D7-H7"]];
unit.getRange("J6:J7").formulas = [["=IF(D6=0,0,I6/D6)"], ["=IF(D7=0,0,I7/D7)"]];
unit.getRange("K6:K7").formulas = [["='Assumptions'!E56/'Assumptions'!B35"], ["='Assumptions'!E56/'Assumptions'!B35"]];
unit.getRange("L6:L7").formulas = [["=I6-K6"], ["=I7-K7"]];
for (const col of ["B", "C", "D", "E", "F", "G", "H", "I", "K", "L"]) {
  unit.getRange(`${col}8`).formulas = [[`=${col}6*'Assumptions'!B10+${col}7*'Assumptions'!C10`]];
}
unit.getRange("J8").formulas = [["=I8/D8"]];
formulaStyle(unit, "B6:L8", true);
unit.getRange("B6:I8").format.numberFormat = money1;
unit.getRange("J6:J8").format.numberFormat = pct;
unit.getRange("K6:L8").format.numberFormat = money1;
unit.getRange("A8:L8").format = {
  fill: C.limeSoft,
  font: { bold: true, color: C.ink },
  borders: { top: { style: "thin", color: C.ink } },
};

section(unit, "A11:L11", "Brand partner sponsored-night economics");
unit.getRange("A12:H12").values = [["Offer", "Nights", "Package price", "Effective fee / night", "Expected app check-ins", "Outly revenue", "Direct cost", "Contribution"]];
headers(unit, "A12:H12");
unit.getRange("A13:A16").values = [["One sponsored night"], ["Toronto pilot sponsored night — recommended"], ["Three-night bundle"], ["Six-night bundle"]];
unit.getRange("B13:B16").values = [[1], [1], [3], [6]];
unit.getRange("C13:C16").formulas = [["='Assumptions'!B21"], ["='Assumptions'!B21"], ["='Assumptions'!B22"], ["='Assumptions'!B23"]];
unit.getRange("D13:D16").formulas = [["=C13/B13"], ["=C14/B14"], ["=C15/B15"], ["=C16/B16"]];
unit.getRange("E13:E16").formulas = [["='Assumptions'!B24*B13"], ["='Assumptions'!B24*B14"], ["='Assumptions'!B24*B15"], ["='Assumptions'!B24*B16"]];
unit.getRange("F13:F16").formulas = [
  ["=C13"],
  ["=C14"],
  ["=C15"],
  ["=C16"],
];
unit.getRange("G13:G16").formulas = [
  ["=B13*('Assumptions'!B28*'Assumptions'!B29+'Assumptions'!B30)"],
  ["=B14*('Assumptions'!B28*'Assumptions'!B29+'Assumptions'!B30)"],
  ["=B15*('Assumptions'!B28*'Assumptions'!B29+'Assumptions'!B30)"],
  ["=B16*('Assumptions'!B28*'Assumptions'!B29+'Assumptions'!B30)"],
];
unit.getRange("H13:H16").formulas = [["=F13-G13"], ["=F14-G14"], ["=F15-G15"], ["=F16-G16"]];
unit.getRange("I12:I16").values = [["Margin"], [null], [null], [null], [null]];
headers(unit, "I12:I12");
unit.getRange("I13:I16").formulas = [["=H13/F13"], ["=H14/F14"], ["=H15/F15"], ["=H16/F16"]];
formulaStyle(unit, "C13:I16", true);
unit.getRange("C13:D16").format.numberFormat = money;
unit.getRange("F13:H16").format.numberFormat = money;
unit.getRange("B13:B16").format.numberFormat = countFmt;
unit.getRange("E13:E16").format.numberFormat = countFmt;
unit.getRange("I13:I16").format.numberFormat = pct;
unit.getRange("A14:I14").format = { fill: C.limeSoft, font: { bold: true, color: C.ink } };

unit.getRange("A19:D23").values = [
  ["Recommended advertiser terms", "Price", "Treatment", "Rationale"],
  ["One-night sponsored bar activation", null, "Flat Outly fee", "One brand partner matched with one demographic-fit bar"],
  ["Three-night bundle", null, "Flat bundle fee", "C$2,500 per night; approximately 17% discount"],
  ["Six-night bundle", null, "Flat bundle fee", "C$2,250 per night; 25% discount"],
  ["Advertiser-funded offer budget", null, "Pass-through", "Funded separately; app location check-ins are reporting only"],
];
unit.getRange("B20:B23").formulas = [["='Assumptions'!B21"], ["='Assumptions'!B22"], ["='Assumptions'!B23"], ["='Assumptions'!B27"]];
headers(unit, "A19:D19");
unit.getRange("B20:B23").format.numberFormat = money;

// Toronto pilot
title(pilot, "A1:Q1", "OUTLY — Toronto Pilot Economics");
pilot.getRange("A2:Q2").values = [["First step | 3-month Toronto pilot | CAD before HST and income tax | Blue/yellow cells are editable assumptions", null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]];
pilot.getRange("A2:Q2").merge();
pilot.getRange("A2:Q2").format = { font: { color: C.muted, italic: true, size: 9 } };

for (const [labelRange, label, valueRange, formula] of [
  ["A4:D4", "PILOT TOTAL REVENUE", "A5:D6", "=G16"],
  ["E4:H4", "OPERATING PROFIT BEFORE LAUNCH BUDGET", "E5:H6", "=G40"],
  ["I4:L4", "OPTIONAL ONE-TIME LAUNCH BUDGET", "I5:L6", "=G50"],
  ["M4:Q4", "MAXIMUM FUNDING REQUIRED", "M5:Q6", "=G55"],
]) {
  pilot.getRange(labelRange).merge();
  pilot.getRange(labelRange).values = [[label]];
  pilot.getRange(labelRange).format = { fill: C.charcoal, font: { color: C.white, bold: true }, horizontalAlignment: "center" };
  pilot.getRange(valueRange).merge();
  pilot.getRange(valueRange).formulas = [[formula]];
  pilot.getRange(valueRange).format = {
    fill: C.limeSoft,
    font: { color: C.ink, bold: true, size: 20 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    numberFormat: money,
    borders: { preset: "outside", style: "thin", color: C.line },
  };
}

section(pilot, "A8:H8", "Three-month operating model");
pilot.getRange("A9:H9").values = [["Metric", "Unit", "Pre-launch", "Month 1", "Month 2", "Month 3", "Pilot total", "Notes"]];
headers(pilot, "A9:H9");
pilot.getRange("A10:B41").values = [
  ["Paid pilot venues", "venues"],
  ["Pilot venue price", "CAD / venue / month"],
  ["Venue subscription revenue", "CAD"],
  ["Sponsored bar nights", "matched bar nights"],
  ["Outly fee per sponsored night", "CAD / sponsored night"],
  ["Brand partner revenue", "CAD"],
  ["Total revenue", "CAD"],
  ["Free venue listings", "venues"],
  ["Support hours per paid venue", "hours / paid venue"],
  ["Direct cost per venue", "CAD / venue"],
  ["Venue direct cost", "CAD"],
  ["Direct cost per sponsored night", "CAD / sponsored night"],
  ["Sponsored-night direct cost", "CAD"],
  ["Total direct cost", "CAD"],
  ["Gross profit", "CAD"],
  [null, null],
  ["Supabase Pro", "CAD / month"],
  ["Cloudflare Pages", "CAD / month"],
  ["Apple Developer Program", "CAD / month"],
  ["GoDaddy domain + email", "CAD / month"],
  ["Resend, PostHog, Mapbox and Sentry", "CAD / month"],
  ["1Password", "CAD / month"],
  ["QuickBooks", "CAD / month"],
  ["Sales and marketing", "CAD / month"],
  ["Venue acquisition and travel", "CAD / month"],
  ["Legal and accounting", "CAD / month"],
  ["Other G&A", "CAD / month"],
  ["Pilot contingency", "CAD / month"],
  ["Founder cash draw", "CAD / month"],
  ["Total fixed monthly cost", "CAD"],
  ["Operating profit before launch budget", "CAD"],
  ["Operating margin", "%"],
];
pilot.getRange("C10:F41").values = Array.from({ length: 32 }, () => [0, 0, 0, 0]);
pilot.getRange("D10:F10").values = [[5, 10, 15]];
pilot.getRange("D11:F11").values = [[129, 129, 129]];
pilot.getRange("D13:F13").values = [[0, 1, 1]];
pilot.getRange("D17:F17").values = [[10, 20, 30]];
pilot.getRange("D18:F18").values = [[1, 1, 1]];
inputStyle(pilot, "D10:F11");
inputStyle(pilot, "D13:F13");
inputStyle(pilot, "D17:F18");

pilot.getRange("D12:F12").formulas = [["=D10*D11", "=E10*E11", "=F10*F11"]];
pilot.getRange("D14:F14").formulas = [["='Assumptions'!B21", "='Assumptions'!B21", "='Assumptions'!B21"]];
pilot.getRange("D15:F15").formulas = [["=D13*D14", "=E13*E14", "=F13*F14"]];
pilot.getRange("D16:F16").formulas = [["=D12+D15", "=E12+E15", "=F12+F15"]];
pilot.getRange("D19:F19").formulas = [[
  "=D18*'Assumptions'!C12+'Assumptions'!C13+D11*('Assumptions'!C14+'Assumptions'!C16)+'Assumptions'!C15",
  "=E18*'Assumptions'!C12+'Assumptions'!C13+E11*('Assumptions'!C14+'Assumptions'!C16)+'Assumptions'!C15",
  "=F18*'Assumptions'!C12+'Assumptions'!C13+F11*('Assumptions'!C14+'Assumptions'!C16)+'Assumptions'!C15",
]];
pilot.getRange("D20:F20").formulas = [["=D10*D19+D17*'Unit Economics'!H6", "=E10*E19+E17*'Unit Economics'!H6", "=F10*F19+F17*'Unit Economics'!H6"]];
pilot.getRange("D21:F21").formulas = [["='Unit Economics'!G14", "='Unit Economics'!G14", "='Unit Economics'!G14"]];
pilot.getRange("D22:F22").formulas = [["=D13*D21", "=E13*E21", "=F13*F21"]];
pilot.getRange("D23:F23").formulas = [["=D20+D22", "=E20+E22", "=F20+F22"]];
pilot.getRange("D24:F24").formulas = [["=D16-D23", "=E16-E23", "=F16-F23"]];

pilot.getRange("D26:F32").formulas = [
  ["='Assumptions'!E44", "='Assumptions'!E44", "='Assumptions'!E44"],
  ["='Sources'!B20", "='Sources'!B20", "='Sources'!B20"],
  ["='Assumptions'!E48", "='Assumptions'!E48", "='Assumptions'!E48"],
  ["='Assumptions'!E52", "='Assumptions'!E52", "='Assumptions'!E52"],
  ["=SUM('Sources'!B19:B21)", "=SUM('Sources'!B19:B21)", "=SUM('Sources'!B19:B21)"],
  ["='Assumptions'!E54", "='Assumptions'!E54", "='Assumptions'!E54"],
  ["='Assumptions'!E53", "='Assumptions'!E53", "='Assumptions'!E53"],
];
pilot.getRange("D33:F38").values = [
  [1000, 1000, 1000],
  [500, 500, 500],
  [250, 250, 250],
  [200, 200, 200],
  [50, 50, 50],
  [0, 0, 0],
];
inputStyle(pilot, "D33:F38");
pilot.getRange("D39:F39").formulas = [["=SUM(D26:D38)", "=SUM(E26:E38)", "=SUM(F26:F38)"]];
pilot.getRange("D40:F40").formulas = [["=D24-D39", "=E24-E39", "=F24-F39"]];
pilot.getRange("D41:F41").formulas = [["=IF(D16=0,0,D40/D16)", "=IF(E16=0,0,E40/E16)", "=IF(F16=0,0,F40/F16)"]];

pilot.getRange("G10:G41").formulas = [
  ["=SUM(D10:F10)"], ["=AVERAGE(D11:F11)"], ["=SUM(D12:F12)"], ["=SUM(D13:F13)"],
  ["=AVERAGE(D14:F14)"], ["=SUM(D15:F15)"], ["=G12+G15"], ["=SUM(D17:F17)"],
  ["=AVERAGE(D18:F18)"], ["=AVERAGE(D19:F19)"], ["=SUM(D20:F20)"], ["=AVERAGE(D21:F21)"],
  ["=SUM(D22:F22)"], ["=G20+G22"], ["=SUM(D24:F24)"], [null],
  ["=SUM(D26:F26)"], ["=SUM(D27:F27)"], ["=SUM(D28:F28)"], ["=SUM(D29:F29)"],
  ["=SUM(D30:F30)"], ["=SUM(D31:F31)"], ["=SUM(D32:F32)"], ["=SUM(D33:F33)"],
  ["=SUM(D34:F34)"], ["=SUM(D35:F35)"], ["=SUM(D36:F36)"], ["=SUM(D37:F37)"],
  ["=SUM(D38:F38)"], ["=SUM(D39:F39)"], ["=SUM(D40:F40)"], ["=IF(G16=0,0,G40/G16)"],
];
pilot.getRange("H10:H41").values = [
  ["Editable monthly ramp"], ["Introductory 90-day price; preserve C$199 list price"], ["Venue count × pilot price"],
  ["Editable sponsored-night ramp"], ["Flat one-night activation fee; no setup or per-visit charge"], ["Sponsored nights × flat Outly fee"],
  ["Venue + advertiser revenue"], ["Free supply ramp; carries light support and technology cost"], ["Higher-touch onboarding during pilot"], ["Support, technology and Stripe fees"],
  ["Paid venue cost plus free-listing service cost"], ["Activation operations and creative delivery"], ["Sponsored nights × direct cost per night"],
  ["Venue + sponsored-night direct cost"], ["Revenue less direct cost"], [null], ["Recommended once real-value rewards launch"],
  ["Free commercial static hosting"], ["Annual membership shown monthly"], ["Existing domain and mailbox estimate"],
  ["Expected within free tiers"], ["Security tooling estimate"], ["Accounting software estimate"], ["Consumer and venue launch activity"],
  ["Local meetings, onboarding and travel"], ["Monthly professional-services reserve"], ["Insurance and miscellaneous"],
  ["Small recurring buffer"], ["Set to planned founder cash compensation"], ["Recurring fixed cash costs"],
  ["Gross profit less fixed monthly costs"], ["Operating profit ÷ revenue"],
];

section(pilot, "A43:H43", "Optional one-time launch budget");
pilot.getRange("A44:H44").values = [["Item", "Unit", "Pre-launch", "Month 1", "Month 2", "Month 3", "Pilot total", "Notes"]];
headers(pilot, "A44:H44");
pilot.getRange("A45:B50").values = [
  ["Backend and Supabase integration", "CAD"],
  ["Venue portal and marketing website", "CAD"],
  ["Legal, privacy policy and partner contracts", "CAD"],
  ["Launch creative, App Store QA and testing", "CAD"],
  ["One-time launch contingency", "CAD"],
  ["Total optional launch budget", "CAD"],
];
pilot.getRange("C45:F49").values = [[5000, 0, 0, 0], [3000, 0, 0, 0], [2000, 0, 0, 0], [1000, 0, 0, 0], [1500, 0, 0, 0]];
inputStyle(pilot, "C45:C49");
pilot.getRange("C50").formulas = [["=SUM(C45:C49)"]];
pilot.getRange("D50:F50").formulas = [["=SUM(D45:D49)", "=SUM(E45:E49)", "=SUM(F45:F49)"]];
pilot.getRange("G45:G49").formulas = [["=SUM(C45:F45)"], ["=SUM(C46:F46)"], ["=SUM(C47:F47)"], ["=SUM(C48:F48)"], ["=SUM(C49:F49)"]];
pilot.getRange("G50").formulas = [["=SUM(G45:G49)"]];
pilot.getRange("H45:H50").values = [
  ["Editable external-development allowance; use zero if founder-built"],
  ["Editable external-development allowance"],
  ["Planning reserve; obtain legal quotes"],
  ["Creative production, QA devices and launch testing"],
  ["Approximately 13% of listed launch budget"],
  ["One-time cash required before and during launch"],
];

section(pilot, "A52:H52", "Cash requirement and break-even");
pilot.getRange("A53:H58").values = [
  ["Net cash flow after launch budget", "CAD", null, null, null, null, null, "Operating profit less optional one-time launch budget"],
  ["Cumulative cash flow", "CAD", null, null, null, null, null, "Cash position from start of pilot"],
  ["Maximum funding requirement", "CAD", null, null, null, null, null, "Largest cumulative cash deficit"],
  ["Ending cumulative cash", "CAD", null, null, null, null, null, "Ending cash position after three months"],
  ["Break-even venues with no sponsored nights", "venues", null, null, null, null, null, "At Month 3 pilot price and recurring cost base"],
  ["Break-even venues with one sponsored night", "venues", null, null, null, null, null, "After one sponsored-night contribution"],
];
pilot.getRange("C53:G53").formulas = [["=-C50", "=D40-D50", "=E40-E50", "=F40-F50", "=SUM(C53:F53)"]];
pilot.getRange("C54:G54").formulas = [["=C53", "=C54+D53", "=D54+E53", "=E54+F53", "=F54"]];
pilot.getRange("G55:G58").formulas = [
  ["=MAX(0,-MIN(C54:F54))"],
  ["=F54"],
  ["=MAX(0,ROUNDUP(F39/(F11-F19-(F17/F10)*'Unit Economics'!H6),0))"],
  ["=MAX(0,ROUNDUP((F39-(F14-F21))/(F11-F19-(F17/F10)*'Unit Economics'!H6),0))"],
];

section(pilot, "J28:N28", "Monthly operating profit sensitivity");
pilot.getRange("J29:N29").values = [["Sponsored nights / paid venues", 5, 10, 15, 25]];
headers(pilot, "J29:N29");
pilot.getRange("J30:J32").values = [[0], [1], [2]];
pilot.getRange("K30:N32").formulas = [
  ["=K$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J30*($F$14-$F$21)-$F$39", "=L$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J30*($F$14-$F$21)-$F$39", "=M$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J30*($F$14-$F$21)-$F$39", "=N$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J30*($F$14-$F$21)-$F$39"],
  ["=K$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J31*($F$14-$F$21)-$F$39", "=L$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J31*($F$14-$F$21)-$F$39", "=M$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J31*($F$14-$F$21)-$F$39", "=N$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J31*($F$14-$F$21)-$F$39"],
  ["=K$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J32*($F$14-$F$21)-$F$39", "=L$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J32*($F$14-$F$21)-$F$39", "=M$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J32*($F$14-$F$21)-$F$39", "=N$29*($F$11-$F$19-($F$17/$F$10)*'Unit Economics'!H6)+$J32*($F$14-$F$21)-$F$39"],
];
pilot.getRange("J35:L38").values = [["Month", "Revenue", "Operating profit"], ["Month 1", null, null], ["Month 2", null, null], ["Month 3", null, null]];
pilot.getRange("K36:L38").formulas = [["=D16", "=D40"], ["=E16", "=E40"], ["=F16", "=F40"]];
headers(pilot, "J35:L35");
const pilotChart = pilot.charts.add("bar", pilot.getRange("J35:L38"));
pilotChart.title = "Toronto pilot monthly revenue and operating profit (CAD)";
pilotChart.hasLegend = true;
pilotChart.yAxis = { numberFormatCode: '"C$"#,##0' };
pilotChart.setPosition("J9", "Q25");

formulaStyle(pilot, "D12:G16");
formulaStyle(pilot, "D19:G24");
formulaStyle(pilot, "D26:G32", true);
formulaStyle(pilot, "D39:G41");
formulaStyle(pilot, "C50:G58");
formulaStyle(pilot, "K30:N32");
formulaStyle(pilot, "K36:L38");
pilot.getRange("C10:G40").format.numberFormat = money;
pilot.getRange("D10:F10").format.numberFormat = countFmt;
pilot.getRange("D13:G13").format.numberFormat = countFmt;
pilot.getRange("D17:G17").format.numberFormat = countFmt;
pilot.getRange("D18:G18").format.numberFormat = "0.0";
pilot.getRange("D41:G41").format.numberFormat = pct;
pilot.getRange("C45:G56").format.numberFormat = money;
pilot.getRange("G57:G58").format.numberFormat = countFmt;
pilot.getRange("K30:N32").format.numberFormat = money;
pilot.getRange("K36:L38").format.numberFormat = money;
for (const row of [16, 23, 24, 39, 40, 50, 53, 54]) {
  pilot.getRange(`A${row}:G${row}`).format = { font: { bold: true, color: C.ink }, borders: { top: { style: "thin", color: C.ink } } };
}
pilot.getRange("G55:G56").format = { fill: C.limeSoft, font: { bold: true, color: C.ink }, numberFormat: money };
pilot.getRange("K30:N32").conditionalFormats.add("colorScale", { colors: ["#FEE4E2", "#FFF4B8", "#D7F5DF"], thresholds: ["min", "50%", "max"] });

// Scenarios
title(scenarios, "A1:Q1", "OUTLY — Post-Pilot Monthly Revenue & Profit Scenarios");
scenarios.getRange("A2:Q2").values = [["All outputs are monthly CAD before HST and income tax. Scenario operating investment scales founder/contractor, marketing, legal and G&A assumptions.", null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null]];
noteStyle(scenarios, "A2:Q2");
scenarios.getRange("A2:Q2").merge();
scenarios.getRange("A4:Q4").values = [["Scenario", "Listed venues", "Free venues", "Paid venues", "Sponsored nights", "Operating investment multiplier", "Subscription revenue", "Brand partner revenue", "Total revenue", "Venue direct cost", "Sponsored-night direct cost", "Gross profit", "Platform fixed", "Operating investment", "Operating profit", "Operating margin", "Annualized revenue"]];
headers(scenarios, "A4:Q4");
scenarios.getRange("A5:F8").values = [
  ["Early commercial", 25, null, null, 1, 0.75],
  ["Base", 50, null, null, 2, 1],
  ["Scale", 100, null, null, 4, 1.5],
  ["Growth", 200, null, null, 8, 2],
];
inputStyle(scenarios, "B5:B8");
inputStyle(scenarios, "E5:F8");
scenarios.getRange("C5:C8").formulas = [["=ROUND(B5*'Assumptions'!B10,0)"], ["=ROUND(B6*'Assumptions'!B10,0)"], ["=ROUND(B7*'Assumptions'!B10,0)"], ["=ROUND(B8*'Assumptions'!B10,0)"]];
scenarios.getRange("D5:D8").formulas = [["=B5-C5"], ["=B6-C6"], ["=B7-C7"], ["=B8-C8"]];
scenarios.getRange("G5:G8").formulas = [["=D5*'Unit Economics'!D7"], ["=D6*'Unit Economics'!D7"], ["=D7*'Unit Economics'!D7"], ["=D8*'Unit Economics'!D7"]];
scenarios.getRange("H5:H8").formulas = [["=E5*'Unit Economics'!F14"], ["=E6*'Unit Economics'!F14"], ["=E7*'Unit Economics'!F14"], ["=E8*'Unit Economics'!F14"]];
scenarios.getRange("I5:I8").formulas = [["=SUM(G5:H5)"], ["=SUM(G6:H6)"], ["=SUM(G7:H7)"], ["=SUM(G8:H8)"]];
scenarios.getRange("J5:J8").formulas = [["=C5*'Unit Economics'!H6+D5*'Unit Economics'!H7"], ["=C6*'Unit Economics'!H6+D6*'Unit Economics'!H7"], ["=C7*'Unit Economics'!H6+D7*'Unit Economics'!H7"], ["=C8*'Unit Economics'!H6+D8*'Unit Economics'!H7"]];
scenarios.getRange("K5:K8").formulas = [["=E5*'Unit Economics'!G14"], ["=E6*'Unit Economics'!G14"], ["=E7*'Unit Economics'!G14"], ["=E8*'Unit Economics'!G14"]];
scenarios.getRange("L5:L8").formulas = [["=I5-J5-K5"], ["=I6-J6-K6"], ["=I7-J7-K7"], ["=I8-J8-K8"]];
scenarios.getRange("M5:M8").formulas = [["='Assumptions'!E56"], ["='Assumptions'!E56"], ["='Assumptions'!E56"], ["='Assumptions'!E56"]];
scenarios.getRange("N5:N8").formulas = [["=F5*SUM('Assumptions'!B37:B40)"], ["=F6*SUM('Assumptions'!B37:B40)"], ["=F7*SUM('Assumptions'!B37:B40)"], ["=F8*SUM('Assumptions'!B37:B40)"]];
scenarios.getRange("O5:O8").formulas = [["=L5-M5-N5"], ["=L6-M6-N6"], ["=L7-M7-N7"], ["=L8-M8-N8"]];
scenarios.getRange("P5:P8").formulas = [["=O5/I5"], ["=O6/I6"], ["=O7/I7"], ["=O8/I8"]];
scenarios.getRange("Q5:Q8").formulas = [["=I5*12"], ["=I6*12"], ["=I7*12"], ["=I8*12"]];
formulaStyle(scenarios, "C5:Q8", true);
scenarios.getRange("B5:E8").format.numberFormat = countFmt;
scenarios.getRange("F5:F8").format.numberFormat = "0.00x";
scenarios.getRange("G5:O8").format.numberFormat = money;
scenarios.getRange("P5:P8").format.numberFormat = pct;
scenarios.getRange("Q5:Q8").format.numberFormat = money;
scenarios.getRange("A6:Q6").format = { fill: C.limeSoft, font: { bold: true, color: C.ink } };

section(scenarios, "A11:H11", "Break-even analysis");
scenarios.getRange("A12:B17").values = [
  ["Metric", "Value"],
  ["Blended contribution per listed venue", null],
  ["Contribution from base sponsored nights", null],
  ["Total fixed platform + base operating investment", null],
  ["Listed venues required at base sponsored-night volume", null],
  ["Listed venues required with no sponsored nights", null],
];
headers(scenarios, "A12:B12");
scenarios.getRange("B13").formulas = [["='Unit Economics'!I8"]];
scenarios.getRange("B14").formulas = [["='Assumptions'!B36*'Unit Economics'!H14"]];
scenarios.getRange("B15").formulas = [["='Assumptions'!E56+SUM('Assumptions'!B37:B40)"]];
scenarios.getRange("B16").formulas = [["=MAX(0,ROUNDUP((B15-B14)/B13,0))"]];
scenarios.getRange("B17").formulas = [["=MAX(0,ROUNDUP(B15/B13,0))"]];
formulaStyle(scenarios, "B13:B17", true);
scenarios.getRange("B13:B15").format.numberFormat = money;
scenarios.getRange("B16:B17").format.numberFormat = countFmt;

// Summary
title(summary, "A1:L1", "OUTLY — Pilot-First Pricing, Revenue & Profit Summary");
summary.getRange("A2:L2").values = [["Decision model | CAD | Monthly view | As of 2026-07-18", null, null, null, null, null, null, null, null, null, null, null]];
summary.getRange("A2:L2").merge();
summary.getRange("A2:L2").format = { font: { color: C.muted, italic: true, size: 9 } };

summary.getRange("A4:C4").merge(); summary.getRange("A4:C4").values = [["PILOT VENUE PRICE"]];
summary.getRange("D4:F4").merge(); summary.getRange("D4:F4").values = [["MONTH 3 PAID VENUES"]];
summary.getRange("G4:I4").merge(); summary.getRange("G4:I4").values = [["ONE-NIGHT SPONSOR FEE"]];
summary.getRange("J4:L4").merge(); summary.getRange("J4:L4").values = [["PILOT FUNDING REQUIRED"]];
for (const r of ["A4:C4", "D4:F4", "G4:I4", "J4:L4"]) {
  summary.getRange(r).format = { fill: C.charcoal, font: { color: C.white, bold: true }, horizontalAlignment: "center" };
}
summary.getRange("A5:C7").merge(); summary.getRange("A5:C7").formulas = [["='Toronto Pilot'!F11"]];
summary.getRange("D5:F7").merge(); summary.getRange("D5:F7").formulas = [["='Toronto Pilot'!F10"]];
summary.getRange("G5:I7").merge(); summary.getRange("G5:I7").formulas = [["='Assumptions'!B21"]];
summary.getRange("J5:L7").merge(); summary.getRange("J5:L7").formulas = [["='Toronto Pilot'!G55"]];
for (const r of ["A5:C7", "D5:F7", "G5:I7", "J5:L7"]) {
  summary.getRange(r).format = {
    fill: C.limeSoft,
    font: { color: C.ink, bold: true, size: 22 },
    horizontalAlignment: "center",
    verticalAlignment: "center",
    numberFormat: money,
    borders: { preset: "outside", style: "thin", color: C.line },
  };
}
summary.getRange("D5:F7").format.numberFormat = countFmt;

section(summary, "A10:F10", "Recommended pricing");
summary.getRange("A11:F11").values = [["Offer", "Monthly", "Annual", "What is included", "Discount posture", "Primary value"]];
headers(summary, "A11:F11");
summary.getRange("A12:F15").values = [
  ["Free listing", 0, 0, "Basic profile and standard discovery", "Permanent free acquisition tier", "Build Toronto venue supply"],
  ["Paid membership", 199, 1990, "Offers, analytics, promoted placement and brand-partner reporting", "Pilot at C$129 for 90 days", "Measurable traffic and promotion"],
  [null, null, null, null, null, null],
  [null, null, null, null, null, null],
];
summary.getRange("B12:C13").format.numberFormat = money;
summary.getRange("A13:F13").format.fill = C.paper;

section(summary, "H10:L10", "Toronto pilot economics");
summary.getRange("H11:I18").values = [
  ["Metric", "Value"],
  ["Pilot duration (months)", null],
  ["Month 3 paid venues", null],
  ["Total pilot revenue", null],
  ["Operating profit before launch budget", null],
  ["Optional one-time launch budget", null],
  ["Maximum funding requirement", null],
  ["Ending cumulative cash", null],
];
headers(summary, "H11:I11");
summary.getRange("I12:I18").formulas = [
  ["=3"],
  ["='Toronto Pilot'!F10"],
  ["='Toronto Pilot'!G16"],
  ["='Toronto Pilot'!G40"],
  ["='Toronto Pilot'!G50"],
  ["='Toronto Pilot'!G55"],
  ["='Toronto Pilot'!G56"],
];
formulaStyle(summary, "I12:I18", true);
summary.getRange("I12:I13").format.numberFormat = countFmt;
summary.getRange("I14:I18").format.numberFormat = money;

summary.getRange("A19:C23").values = [["Post-pilot scenario", "Monthly revenue", "Operating profit"], ["Early commercial", null, null], ["Base", null, null], ["Scale", null, null], ["Growth", null, null]];
headers(summary, "A19:C19");
summary.getRange("B20:C23").formulas = [
  ["='Scenarios'!I5", "='Scenarios'!O5"],
  ["='Scenarios'!I6", "='Scenarios'!O6"],
  ["='Scenarios'!I7", "='Scenarios'!O7"],
  ["='Scenarios'!I8", "='Scenarios'!O8"],
];
formulaStyle(summary, "B20:C23", true);
summary.getRange("B20:C23").format.numberFormat = money;
const scenarioChart = summary.charts.add("bar", summary.getRange("A19:C23"));
scenarioChart.title = "Post-pilot revenue and operating profit by scale (CAD/month)";
scenarioChart.hasLegend = true;
scenarioChart.yAxis = { numberFormatCode: '"C$"#,##0' };
scenarioChart.setPosition("E19", "L32");

section(summary, "A26:D26", "Brand partner model");
summary.getRange("A27:D32").values = [
  ["Component", "Recommended charge", "Billing basis", "Treatment"],
  ["One-night sponsored activation", 3000, "Per matched bar night", "Flat Outly revenue"],
  ["Three-night bundle", 7500, "Per bundle", "Flat Outly revenue"],
  ["Six-night bundle", 13500, "Per bundle", "Flat Outly revenue"],
  ["Advertiser-funded offer budget", 2000, "Funded separately", "Pass-through cash"],
  ["In-app location check-ins", 0, "Reporting metric only", "No advertiser billing"],
];
headers(summary, "A27:D27");
summary.getRange("B28:B32").format.numberFormat = money;

summary.getRange("A34:L36").merge();
summary.getRange("A34:L36").values = [["First step: offer bars a permanent Free Listing or one Paid Membership. Run a three-month Toronto pilot at C$129 per paid venue per month, ramping from 5 to 10 to 15 paid venues while building free supply. Sell one flat C$3,000 sponsored bar night in Months 2 and 3, matching each brand partner to a demographic-fit bar. App location check-ins are reported for analytics only and do not determine price. Move the paid membership to C$199/month after validation."]];
summary.getRange("A34:L36").format = {
  fill: C.ink,
  font: { color: C.white, bold: true, size: 11 },
  wrapText: true,
  verticalAlignment: "center",
};
summary.getRange("A34:L36").format.rowHeight = 26;

// Sources
title(sources, "A1:I1", "OUTLY — Sources & Audit Trail");
sources.getRange("A3:I3").values = [["Item", "Value", "Currency / unit", "Billing / threshold", "Source type", "Source name", "URL", "Accessed", "Model note"]];
headers(sources, "A3:I3");
sources.getRange("A4:I21").values = [
  ["Supabase Pro", 25, "USD", "Monthly", "External", "Supabase pricing", "https://supabase.com/pricing", "2026-07-18", "Production database, auth, storage and functions"],
  ["Vercel Pro", 20, "USD", "Monthly", "External", "Vercel pricing", "https://vercel.com/pricing", "2026-07-18", "Commercial hosting; includes US$20 usage credit"],
  ["Sentry Team", 26, "USD", "Monthly; billed annually", "External", "Sentry pricing", "https://sentry.io/pricing/", "2026-07-18", "Use Developer at zero cost until team access is needed"],
  ["Resend Pro", 20, "USD", "50,000 emails/month", "External", "Resend pricing", "https://resend.com/pricing", "2026-07-18", "GoDaddy remains the staff mailbox"],
  ["Apple Developer Program", 99, "USD", "Annual", "External", "Apple Developer", "https://developer.apple.com/programs/whats-included/", "2026-07-18", "Includes 25 Xcode Cloud compute hours/month"],
  ["PostHog product analytics", 0, "USD", "First 1M events/month", "External", "PostHog pricing", "https://posthog.com/pricing", "2026-07-18", "Usage cost begins beyond free tier"],
  ["Mapbox Maps SDK mobile", 0, "USD", "Up to 25k MAU", "External", "Mapbox pricing", "https://www.mapbox.com/pricing", "2026-07-18", "Then US$4 per 1,000 MAU in next tier"],
  ["Stripe Payments", 0.029, "% + C$0.30", "Domestic cards", "External", "Stripe Canada pricing", "https://stripe.com/en-ca/pricing", "2026-07-18", "Applied conservatively to venue subscriptions"],
  ["Stripe Billing", 0.007, "% of Billing volume", "Pay as you go", "External", "Stripe Canada pricing", "https://stripe.com/en-ca/pricing", "2026-07-18", "Additional to Payments processing"],
  ["USD/CAD planning rate", 1.42, "CAD per USD", "Rounded", "External", "Bank of Canada daily rates", "https://www.bankofcanada.ca/rates/exchange/daily-exchange-rates/", "2026-07-18", "Update before approving a budget"],
  ["GoDaddy domain and email", 5, "CAD/month", "Estimate", "User-provided + estimate", "Existing Outly account", "https://www.godaddy.com/", "2026-07-18", "getoutly.app purchased; included email used for now"],
  ["QuickBooks Online", 40, "CAD/month", "Estimate", "Model assumption", "QuickBooks Canada", "https://quickbooks.intuit.com/ca/pricing/", "2026-07-18", "Replace with actual subscribed plan"],
  ["1Password", 20, "CAD/month", "Estimate", "Model assumption", "1Password", "https://1password.com/pricing", "2026-07-18", "Replace with actual seat count"],
  ["Venue subscription prices", null, "CAD", "Free + one paid plan", "Outly recommendation", "Internal assumption", "", "2026-07-18", "Validate the C$129 pilot and C$199 post-pilot paid price"],
  ["Brand partner pricing", null, "CAD", "Sponsored bar night", "Outly recommendation", "Internal assumption", "", "2026-07-18", "Test flat one-night and bundle pricing; app location check-ins are analytics only"],
  ["Supabase Free", 0, "USD", "50k MAU; 500 MB database; 5 GB egress", "External", "Supabase pricing", "https://supabase.com/pricing", "2026-07-18", "Capacity is sufficient for closed beta; use Pro when real-value rewards launch"],
  ["Cloudflare Pages Free", 0, "USD", "500 builds/month", "External", "Cloudflare Pages limits", "https://developers.cloudflare.com/pages/platform/limits/", "2026-07-18", "Commercial static website and lightweight venue portal hosting"],
  ["Resend Free", 0, "USD", "3,000 emails/month; 100/day", "External", "Resend pricing", "https://resend.com/pricing", "2026-07-18", "Use as custom SMTP for Supabase Auth during pilot"],
];
sources.getRange("B4:B21").format.numberFormat = "0.00";
sources.getRange("B11:B12").format.numberFormat = pct;
sources.getRange("A4:I21").format.wrapText = true;

// Checks
title(checks, "A1:G1", "OUTLY — Model Checks");
checks.getRange("A3:B3").values = [["MODEL STATUS", null]];
checks.getRange("B3").formulas = [["=IF(COUNTIF(F6:F19,\"FAIL\")=0,\"PASS\",\"FAIL\")"]];
checks.getRange("A3:B3").format = { fill: C.charcoal, font: { color: C.white, bold: true } };
checks.getRange("A5:G5").values = [["Check", "Actual", "Expected", "Difference", "Tolerance", "Status", "Where to fix / notes"]];
headers(checks, "A5:G5");
checks.getRange("A6:A19").values = [
  ["Venue mix totals 100%"],
  ["Free annual price <= 12 monthly payments"],
  ["Paid annual price <= 12 monthly payments"],
  ["Three-night bundle price ties to assumption"],
  ["Base revenue equals components"],
  ["Base venue counts tie"],
  ["Base operating profit reconciles"],
  ["Blended contribution margin is sensible"],
  ["Pilot revenue equals components"],
  ["Pilot direct costs equal components"],
  ["Pilot operating profit reconciles"],
  ["Pilot ending cash reconciles"],
  ["Pilot funding requirement is non-negative"],
  ["Pilot sponsored-night fee has no setup or visit component"],
];
checks.getRange("B6:E19").formulas = [
  ["=SUM('Assumptions'!B10:C10)", "=1", "=B6-C6", "=0.0001"],
  ["='Assumptions'!B9", "='Assumptions'!B8*12", "=B7-C7", "=0"],
  ["='Assumptions'!C9", "='Assumptions'!C8*12", "=B8-C8", "=0"],
  ["='Unit Economics'!F15", "='Assumptions'!B22", "=B9-C9", "=0.01"],
  ["='Scenarios'!I6", "='Scenarios'!G6+'Scenarios'!H6", "=B10-C10", "=0.01"],
  ["='Scenarios'!B6", "='Scenarios'!C6+'Scenarios'!D6", "=B11-C11", "=0"],
  ["='Scenarios'!O6", "='Scenarios'!L6-'Scenarios'!M6-'Scenarios'!N6", "=B12-C12", "=0.01"],
  ["='Unit Economics'!J8", "=0.75", "=B13-C13", "=0.25"],
  ["='Toronto Pilot'!G16", "='Toronto Pilot'!G12+'Toronto Pilot'!G15", "=B14-C14", "=0.01"],
  ["='Toronto Pilot'!G23", "='Toronto Pilot'!G20+'Toronto Pilot'!G22", "=B15-C15", "=0.01"],
  ["='Toronto Pilot'!G40", "='Toronto Pilot'!G24-'Toronto Pilot'!G39", "=B16-C16", "=0.01"],
  ["='Toronto Pilot'!G56", "='Toronto Pilot'!G40-'Toronto Pilot'!G50", "=B17-C17", "=0.01"],
  ["='Toronto Pilot'!G55", "=0", "=B18-C18", "=0"],
  ["='Toronto Pilot'!G14", "='Assumptions'!B21", "=B19-C19", "=0.01"],
];
checks.getRange("F6:F19").formulas = [
  ["=IF(ABS(D6)<=E6,\"OK\",\"FAIL\")"],
  ["=IF(B7<=C7,\"OK\",\"FAIL\")"],
  ["=IF(B8<=C8,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D9)<=E9,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D10)<=E10,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D11)<=E11,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D12)<=E12,\"OK\",\"FAIL\")"],
  ["=IF(AND(B13>=0.5,B13<=0.95),\"OK\",\"FAIL\")"],
  ["=IF(ABS(D14)<=E14,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D15)<=E15,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D16)<=E16,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D17)<=E17,\"OK\",\"FAIL\")"],
  ["=IF(B18>=0,\"OK\",\"FAIL\")"],
  ["=IF(ABS(D19)<=E19,\"OK\",\"FAIL\")"],
];
checks.getRange("G6:G19").values = [
  ["Assumptions B10:C10"],
  ["Assumptions B8:B9"],
  ["Assumptions C8:C9"],
  ["Unit Economics F15 / Assumptions B22"],
  ["Scenarios G6:I6"],
  ["Scenarios B6:D6"],
  ["Scenarios L6:O6"],
  ["Unit Economics D8:J8"],
  ["Toronto Pilot G12:G16"],
  ["Toronto Pilot G20:G23"],
  ["Toronto Pilot G24:G40"],
  ["Toronto Pilot G40:G56"],
  ["Toronto Pilot G55"],
  ["Toronto Pilot G14 / Assumptions B21"],
];
checks.getRange("B6:E6").format.numberFormat = pct;
checks.getRange("B7:E9").format.numberFormat = money;
checks.getRange("B10:E12").format.numberFormat = money;
checks.getRange("B11:E11").format.numberFormat = countFmt;
checks.getRange("B13:E13").format.numberFormat = pct;
checks.getRange("B14:E19").format.numberFormat = money;
checks.getRange("F6:F19").conditionalFormats.add("containsText", { text: "OK", format: { fill: "#D7F5DF", font: { color: "#067647", bold: true } } });
checks.getRange("F6:F19").conditionalFormats.add("containsText", { text: "FAIL", format: { fill: "#FEE4E2", font: { color: C.red, bold: true } } });
checks.getRange("B3").conditionalFormats.add("containsText", { text: "PASS", format: { fill: C.lime, font: { color: C.ink, bold: true } } });
checks.getRange("B3").conditionalFormats.add("containsText", { text: "FAIL", format: { fill: "#FEE4E2", font: { color: C.red, bold: true } } });

// Comments on source-backed assumptions
workbook.comments.setSelf({ displayName: "User" });
const comments = [
  ["B44", "Source: https://supabase.com/pricing | Pro starts at US$25/month | Accessed 2026-07-18"],
  ["B45", "Source: https://vercel.com/pricing | Pro US$20/month | Accessed 2026-07-18"],
  ["B46", "Source: https://sentry.io/pricing/ | Team US$26/month billed annually | Accessed 2026-07-18"],
  ["B47", "Source: https://resend.com/pricing | Pro US$20/month for 50,000 emails | Accessed 2026-07-18"],
  ["B48", "Source: https://developer.apple.com/programs/whats-included/ | US$99/year | Accessed 2026-07-18"],
  ["B49", "Source: https://posthog.com/pricing | First 1M product analytics events/month free | Accessed 2026-07-18"],
  ["B50", "Source: https://www.mapbox.com/pricing | Mobile Maps free through 25k MAU | Accessed 2026-07-18"],
  ["B51", "Source: Apple Developer membership includes 25 Xcode Cloud compute hours/month | Accessed 2026-07-18"],
  ["B59", "Source: https://www.bankofcanada.ca/rates/exchange/daily-exchange-rates/ | Rounded planning rate; update before budgeting"],
];
for (const [cell, text] of comments) workbook.comments.addThread({ cell: assumptions.getRange(cell) }, text);
const pilotComments = [
  ["D10", "Assumption: paid venue ramp of 5, 10 and 15 across the three-month Toronto pilot | Owner: Outly | Date: 2026-07-18"],
  ["D11", "Assumption: C$129/month introductory paid membership during the 90-day pilot | Owner: Outly | Date: 2026-07-18"],
  ["D13", "Assumption: no sponsored bar night in Month 1 and one one-night brand activation in Months 2 and 3 | Owner: Outly | Date: 2026-07-18"],
  ["D14", "Assumption: flat C$3,000 fee per one-night sponsored bar activation; no setup fee and no per-visit billing. App location check-ins are used only for reporting | Owner: Outly | Date: 2026-07-18"],
  ["D17", "Assumption: free venue listings ramp from 10 to 20 to 30; free listings carry support and technology cost | Owner: Outly | Date: 2026-07-18"],
  ["D18", "Assumption: one support hour per paid pilot venue per month | Owner: Outly | Date: 2026-07-18"],
  ["D26", "Source: https://supabase.com/pricing | Pro starts at US$25/month and is recommended when real-value rewards launch | Accessed 2026-07-18"],
  ["D27", "Source: https://developers.cloudflare.com/pages/platform/limits/ | Free tier used for pilot website hosting | Accessed 2026-07-18"],
  ["D33", "Assumption: C$1,000/month sales and marketing cash budget | Owner: Outly | Date: 2026-07-18"],
  ["D34", "Assumption: C$500/month for Toronto venue acquisition, meetings and travel | Owner: Outly | Date: 2026-07-18"],
  ["D35", "Assumption: C$250/month legal and accounting reserve during pilot | Owner: Outly | Date: 2026-07-18"],
  ["C45", "Assumption: C$5,000 external backend integration allowance; change to zero if founder-built | Owner: Outly | Date: 2026-07-18"],
  ["C46", "Assumption: C$3,000 external website and venue portal allowance | Owner: Outly | Date: 2026-07-18"],
  ["C47", "Assumption: C$2,000 legal, privacy and partner-contract setup reserve | Owner: Outly | Date: 2026-07-18"],
  ["C48", "Assumption: C$1,000 launch creative, QA and testing reserve | Owner: Outly | Date: 2026-07-18"],
  ["C49", "Assumption: C$1,500 one-time setup contingency | Owner: Outly | Date: 2026-07-18"],
];
for (const [cell, text] of pilotComments) workbook.comments.addThread({ cell: pilot.getRange(cell) }, text);

// Layout
pilot.freezePanes.freezeRows(9);
assumptions.freezePanes.freezeRows(7);
unit.freezePanes.freezeRows(5);
scenarios.freezePanes.freezeRows(4);
sources.freezePanes.freezeRows(3);
checks.freezePanes.freezeRows(5);

const widths = [
  [pilot, [["A1:A58", 38], ["B1:B58", 22], ["C1:G58", 16], ["H1:H58", 48], ["I1:I58", 4], ["J1:Q58", 17]]],
  [assumptions, [["A1:A66", 31], ["B1:B66", 15], ["C1:C66", 24], ["D1:D66", 26], ["E1:E66", 20], ["F1:F66", 42]]],
  [unit, [["A1:A24", 30], ["B1:L24", 18], ["D19:D24", 38]]],
  [scenarios, [["A1:A18", 34], ["B1:Q18", 16]]],
  [summary, [["A1:A36", 24], ["B1:C36", 16], ["D1:D36", 33], ["E1:L36", 16]]],
  [sources, [["A1:A22", 28], ["B1:B22", 14], ["C1:F22", 18], ["G1:G22", 48], ["H1:H22", 14], ["I1:I22", 38]]],
  [checks, [["A1:A20", 44], ["B1:F20", 16], ["G1:G20", 38]]],
];
for (const [sheet, defs] of widths) {
  for (const [range, width] of defs) sheet.getRange(range).format.columnWidth = width;
  const used = sheet.getUsedRange();
  if (used) used.format.verticalAlignment = "center";
}
assumptions.getRange("F8:F55").format.wrapText = true;
assumptions.getRange("D20:D31").format.wrapText = true;
assumptions.getRange("A26:F26").format.rowHeight = 30;
unit.getRange("A1:L24").format.wrapText = true;
unit.getRange("J1:K24").format.columnWidth = 22;
scenarios.getRange("A1:Q18").format.wrapText = true;
summary.getRange("A1:L36").format.wrapText = true;
pilot.getRange("A1:Q58").format.wrapText = true;
pilot.getRange("H10:H58").format.rowHeight = 30;
sources.getRange("A3:I21").format.rowHeight = 38;

// Compact inspections and renders for QA
const summaryInspect = await workbook.inspect({ kind: "table", range: "Summary!A1:L36", include: "values,formulas", tableMaxRows: 36, tableMaxCols: 12 });
const pilotInspect = await workbook.inspect({ kind: "table", range: "Toronto Pilot!A1:H58", include: "values,formulas", tableMaxRows: 58, tableMaxCols: 8 });
const unitInspect = await workbook.inspect({ kind: "table", range: "Unit Economics!A1:L23", include: "values,formulas", tableMaxRows: 23, tableMaxCols: 12 });
const checksInspect = await workbook.inspect({ kind: "table", range: "Checks!A3:G19", include: "values,formulas", tableMaxRows: 19, tableMaxCols: 7 });
const errorInspect = await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 }, summary: "final formula error scan" });
const baseProfitTrace = await workbook.trace("Scenarios!O6");
const pilotFundingTrace = await workbook.trace("Toronto Pilot!G55");
console.log(summaryInspect.ndjson);
console.log(pilotInspect.ndjson);
console.log(unitInspect.ndjson);
console.log(checksInspect.ndjson);
console.log(errorInspect.ndjson);
console.log(JSON.stringify(baseProfitTrace).slice(0, 5000));
console.log(JSON.stringify(pilotFundingTrace).slice(0, 5000));

for (const [sheetName, range] of [
  ["Summary", "A1:L36"],
  ["Toronto Pilot", "A1:Q58"],
  ["Assumptions", "A1:F66"],
  ["Unit Economics", "A1:L24"],
  ["Scenarios", "A1:Q18"],
  ["Checks", "A1:G20"],
  ["Sources", "A1:I21"],
]) {
  const preview = await workbook.render({ sheetName, range, scale: 1.2, format: "png" });
  await fs.writeFile(`${outputDir}/${sheetName.toLowerCase().replaceAll(" ", "_")}.png`, new Uint8Array(await preview.arrayBuffer()));
}

const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(`${outputDir}/Outly_Revenue_Pricing_Model.xlsx`);
console.log(`${outputDir}/Outly_Revenue_Pricing_Model.xlsx`);
