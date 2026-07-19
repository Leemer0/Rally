import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const outputDir = "/Users/liam/Repos/Rally/outputs/019f7757-c91f-7b90-abe3-9f070a6e80c5";
await fs.mkdir(outputDir, { recursive: true });

const workbook = Workbook.create();
const pilot = workbook.worksheets.add("Toronto Pilot");

const C = {
  ink: "#0B0D0E", charcoal: "#171A1C", lime: "#C7FF3D", limeSoft: "#EDFFC1",
  silver: "#E7EAEC", line: "#CBD1D5", paper: "#F7F8F8", white: "#FFFFFF",
  blue: "#0000FF", red: "#D92D20", yellow: "#FFF4B8", muted: "#5F686E",
};
const money = '"C$"#,##0;[Red]("C$"#,##0);-';
const money1 = '"C$"#,##0.00;[Red]("C$"#,##0.00);-';
const pct = '0.0%;[Red](0.0%);-';
const countFmt = '#,##0;[Red](#,##0);-';

function title(range, text) {
  const r = pilot.getRange(range); r.merge(); r.values = [[text]];
  r.format = { fill: C.ink, font: { color: C.white, bold: true, size: 20 }, verticalAlignment: "center" };
  r.format.rowHeight = 34;
}
function section(range, text) {
  const r = pilot.getRange(range); r.merge(); r.values = [[text]];
  r.format = { fill: C.charcoal, font: { color: C.white, bold: true, size: 11 }, verticalAlignment: "center" };
  r.format.rowHeight = 22;
}
function headers(range) {
  pilot.getRange(range).format = { fill: C.silver, font: { color: C.ink, bold: true },
    borders: { bottom: { style: "thin", color: C.ink } }, verticalAlignment: "center", wrapText: true };
}
function input(range) { pilot.getRange(range).format = { fill: C.yellow, font: { color: C.blue } }; }
function formula(range) { pilot.getRange(range).format.font = { color: C.ink }; }

pilot.showGridLines = false;
title("A1:Q1", "OUTLY — Toronto Subscription Pilot Model");
pilot.getRange("A2:Q2").merge();
pilot.getRange("A2:Q2").values = [["3-month Toronto pilot | CAD before HST and income tax | Cash-profit view | Yellow/blue cells are editable | Version 2.0 — 2026-07-18"]];
pilot.getRange("A2:Q2").format = { font: { color: C.muted, italic: true, size: 9 }, wrapText: true };

for (const [labelRange, label, valueRange, f] of [
  ["A4:D4", "SUBSCRIPTION REVENUE", "A5:D6", "=G12"],
  ["E4:H4", "CASH OPERATING PROFIT", "E5:H6", "=G38"],
  ["I4:L4", "FUTURE OTHER REVENUE", "I5:L6", "=G14"],
  ["M4:Q4", "MAXIMUM FUNDING REQUIRED", "M5:Q6", "=G55"],
]) {
  pilot.getRange(labelRange).merge();
  pilot.getRange(labelRange).values = [[label]];
  pilot.getRange(labelRange).format = { fill: C.charcoal, font: { color: C.white, bold: true }, horizontalAlignment: "center" };
  pilot.getRange(labelRange).format.rowHeight = 22;
  pilot.getRange(valueRange).merge(); pilot.getRange(valueRange).formulas = [[f]];
  pilot.getRange(valueRange).format = { fill: C.limeSoft, font: { color: C.ink, bold: true, size: 20 },
    horizontalAlignment: "center", verticalAlignment: "center", numberFormat: money,
    borders: { preset: "outside", style: "thin", color: C.line } };
}

section("A8:H8", "Subscription revenue and pilot profit");
pilot.getRange("A9:H9").values = [["Metric", "Unit", "Pre-launch", "Month 1", "Month 2", "Month 3", "Pilot total", "Notes"]];
headers("A9:H9");
pilot.getRange("A10:B41").values = [
  ["Paid bars", "bars"], ["Pilot subscription price", "CAD / bar / month"], ["Subscription revenue", "CAD"],
  ["Free bar listings", "bars"], ["Future partner / other revenue", "CAD"], ["Total revenue", "CAD"],
  [null, null], ["Support hours per paid bar", "hours / paid bar"], ["Cash support cost per hour", "CAD / hour"],
  ["Direct cost per paid bar", "CAD / paid bar"], ["Paid-bar direct cost", "CAD"], ["Free-listing direct cost", "CAD"],
  ["Future partner / other direct cost", "CAD"], ["Total direct cost", "CAD"], ["Gross profit", "CAD"],
  [null, null], ["Supabase Free", "CAD / month"], ["Cloudflare Pages Free", "CAD / month"],
  ["Apple Developer Program", "CAD / month"], ["GoDaddy domain + included email", "CAD / month"],
  ["Other software / analytics", "CAD / month"], ["Sales and marketing", "CAD / month"],
  ["Venue acquisition and travel", "CAD / month"], ["Legal and accounting", "CAD / month"],
  ["Other G&A", "CAD / month"], ["Pilot contingency", "CAD / month"], ["Founder cash draw", "CAD / month"],
  ["Total fixed monthly cash cost", "CAD"], ["Cash operating profit", "CAD"], ["Cash operating margin", "%"],
  [null, null], ["Note", null],
];
pilot.getRange("C10:F41").values = Array.from({ length: 32 }, () => [0, 0, 0, 0]);
pilot.getRange("C16:F16").values = [[null, null, null, null]];
pilot.getRange("C25:F25").values = [[null, null, null, null]];
pilot.getRange("C40:F40").values = [[null, null, null, null]];
pilot.getRange("D10:F10").values = [[5, 10, 15]];
pilot.getRange("D11:F11").values = [[129, 129, 129]];
pilot.getRange("D13:F13").values = [[10, 20, 30]];
pilot.getRange("D14:F14").values = [[0, 0, 0]];
pilot.getRange("D17:F17").values = [[1, 1, 1]];
pilot.getRange("D18:F18").values = [[0, 0, 0]];
for (const r of ["D10:F11", "D13:F14", "D17:F18"]) input(r);

pilot.getRange("D12:F12").formulas = [["=D10*D11", "=E10*E11", "=F10*F11"]];
pilot.getRange("D15:F15").formulas = [["=D12+D14", "=E12+E14", "=F12+F14"]];
pilot.getRange("D19:F19").formulas = [[
  "=D17*D18+$K$32+D11*$K$34+$K$35", "=E17*E18+$K$32+E11*$K$34+$K$35", "=F17*F18+$K$32+F11*$K$34+$K$35",
]];
pilot.getRange("D20:F20").formulas = [["=D10*D19", "=E10*E19", "=F10*F19"]];
pilot.getRange("D21:F21").formulas = [["=D13*$K$33", "=E13*$K$33", "=F13*$K$33"]];
pilot.getRange("D22:F22").values = [[0, 0, 0]]; input("D22:F22");
pilot.getRange("D23:F23").formulas = [["=SUM(D20:D22)", "=SUM(E20:E22)", "=SUM(F20:F22)"]];
pilot.getRange("D24:F24").formulas = [["=D15-D23", "=E15-E23", "=F15-F23"]];

pilot.getRange("D26:F36").values = [
  [0, 0, 0], [0, 0, 0], [12, 12, 12], [5, 5, 5], [0, 0, 0], [0, 0, 0],
  [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0],
];
input("D26:F36");
pilot.getRange("D37:F37").formulas = [["=SUM(D26:D36)", "=SUM(E26:E36)", "=SUM(F26:F36)"]];
pilot.getRange("D38:F38").formulas = [["=D24-D37", "=E24-E37", "=F24-F37"]];
pilot.getRange("D39:F39").formulas = [["=IF(D15=0,0,D38/D15)", "=IF(E15=0,0,E38/E15)", "=IF(F15=0,0,F38/F15)"]];
pilot.getRange("A41:H41").merge();
pilot.getRange("A41:H41").values = [["Cash profit excludes unpaid founder time, income tax and HST. Discretionary expenses default to zero until a real pilot budget is approved."]];
pilot.getRange("A41:H41").format = { fill: C.paper, font: { color: C.muted, italic: true, size: 9 }, wrapText: true };

pilot.getRange("G10:G39").formulas = [
  ["=SUM(D10:F10)"], ["=AVERAGE(D11:F11)"], ["=SUM(D12:F12)"], ["=SUM(D13:F13)"], ["=SUM(D14:F14)"], ["=SUM(D15:F15)"], [null],
  ["=AVERAGE(D17:F17)"], ["=AVERAGE(D18:F18)"], ["=AVERAGE(D19:F19)"], ["=SUM(D20:F20)"], ["=SUM(D21:F21)"], ["=SUM(D22:F22)"],
  ["=SUM(D23:F23)"], ["=SUM(D24:F24)"], [null], ["=SUM(D26:F26)"], ["=SUM(D27:F27)"], ["=SUM(D28:F28)"], ["=SUM(D29:F29)"],
  ["=SUM(D30:F30)"], ["=SUM(D31:F31)"], ["=SUM(D32:F32)"], ["=SUM(D33:F33)"], ["=SUM(D34:F34)"], ["=SUM(D35:F35)"],
  ["=SUM(D36:F36)"], ["=SUM(D37:F37)"], ["=SUM(D38:F38)"], ["=IF(G15=0,0,G38/G15)"],
];
pilot.getRange("H10:H39").values = [
  ["Editable paid-bar ramp"], ["Editable 90-day pilot price"], ["Paid bars × subscription price"], ["Editable free listing ramp"],
  ["Placeholder only; leave at zero until partner economics are decided"], ["Subscription plus optional other revenue"], [null],
  ["Time estimate"], ["Zero while founder-delivered; enter a paid cash rate later"], ["Support cash + technology + Stripe"],
  ["Paid bars × direct cost per paid bar"], ["Free listings × free-listing technology cost"],
  ["Placeholder only; leave at zero until the model is decided"], ["All direct cash costs"], ["Revenue less direct costs"], [null],
  ["Free tier assumed sufficient for Toronto pilot"], ["Free commercial static hosting"], ["Annual membership shown monthly"],
  ["Existing getoutly.app domain and included mailbox estimate"], ["Leave zero while free tiers are sufficient"],
  ["Editable; zero until approved"], ["Editable; zero until approved"], ["Editable; zero until approved"],
  ["Editable; zero until approved"], ["Editable; zero until approved"], ["Editable; zero unless founders take cash compensation"],
  ["Known and approved recurring cash costs"], ["Gross profit less fixed monthly cash costs"], ["Cash operating profit ÷ total revenue"],
];

for (const r of [15, 23, 24, 37, 38]) pilot.getRange(`A${r}:G${r}`).format = { font: { bold: true, color: C.ink }, borders: { top: { style: "thin", color: C.ink } } };
formula("D12:G15"); formula("D19:G24"); formula("D37:G39");
pilot.getRange("C10:G38").format.numberFormat = money;
for (const r of [10, 13]) pilot.getRange(`D${r}:G${r}`).format.numberFormat = countFmt;
pilot.getRange("D17:G17").format.numberFormat = "0.0";
pilot.getRange("D39:G39").format.numberFormat = pct;

section("A43:H43", "Optional one-time launch cash budget");
pilot.getRange("A44:H44").values = [["Item", "Unit", "Pre-launch", "Month 1", "Month 2", "Month 3", "Pilot total", "Notes"]]; headers("A44:H44");
pilot.getRange("A45:B50").values = [
  ["External backend work", "CAD"], ["Website / venue portal work", "CAD"], ["Legal, privacy and contracts", "CAD"],
  ["Creative, QA and launch testing", "CAD"], ["Other one-time cost", "CAD"], ["Total optional launch budget", "CAD"],
];
pilot.getRange("C45:F49").values = Array.from({ length: 5 }, () => [0, 0, 0, 0]); input("C45:F49");
pilot.getRange("C50:F50").formulas = [["=SUM(C45:C49)", "=SUM(D45:D49)", "=SUM(E45:E49)", "=SUM(F45:F49)"]];
pilot.getRange("G45:G49").formulas = [["=SUM(C45:F45)"], ["=SUM(C46:F46)"], ["=SUM(C47:F47)"], ["=SUM(C48:F48)"], ["=SUM(C49:F49)"]];
pilot.getRange("G50").formulas = [["=SUM(G45:G49)"]];
pilot.getRange("H45:H50").values = [["Optional input; zero if founder-built"], ["Optional input; zero if founder-built"], ["Enter actual quotes when approved"], ["Enter actual spend when approved"], ["Optional input"], ["Excluded unless entered"]];
pilot.getRange("C45:G50").format.numberFormat = money; formula("C50:G50");
pilot.getRange("A50:G50").format = { font: { bold: true, color: C.ink }, borders: { top: { style: "thin", color: C.ink } } };

section("A52:H52", "Cash requirement and subscription break-even");
pilot.getRange("A53:H57").values = [
  ["Net cash flow", "CAD", null, null, null, null, null, "Cash operating profit less optional one-time launch budget"],
  ["Cumulative cash flow", "CAD", null, null, null, null, null, "Cash position from start of pilot"],
  ["Maximum funding requirement", "CAD", null, null, null, null, null, "Largest cumulative cash deficit"],
  ["Ending cumulative cash", "CAD", null, null, null, null, null, "Ending cash after three months"],
  ["Break-even paid bars", "bars", null, null, null, null, null, "At Month 3 free-to-paid mix and recurring cash cost base"],
];
pilot.getRange("C53:G53").formulas = [["=-C50", "=D38-D50", "=E38-E50", "=F38-F50", "=SUM(C53:F53)"]];
pilot.getRange("C54:G54").formulas = [["=C53", "=C54+D53", "=D54+E53", "=E54+F53", "=F54"]];
pilot.getRange("G55:G57").formulas = [["=MAX(0,-MIN(C54:F54))"], ["=F54"], ["=IFERROR(MAX(0,ROUNDUP(F37/(F11-F19-(F13/F10)*$K$33),0)),0)"]];
pilot.getRange("C53:G56").format.numberFormat = money; pilot.getRange("G57").format.numberFormat = countFmt;
for (const r of [53, 54]) pilot.getRange(`A${r}:G${r}`).format = { font: { bold: true, color: C.ink }, borders: { top: { style: "thin", color: C.ink } } };
pilot.getRange("G55:G56").format = { fill: C.limeSoft, font: { bold: true, color: C.ink }, numberFormat: money };

section("J28:M28", "Subscription cost assumptions");
pilot.getRange("J29:M29").values = [["Driver", "Value", "Unit", "Notes"]]; headers("J29:M29");
pilot.getRange("J30:M35").values = [
  ["Support hours per paid bar", 1, "hours / month", "Time estimate"], ["Cash support rate", 0, "CAD / hour", "Founder-delivered during pilot"],
  ["Paid technology cost", 4, "CAD / paid bar / month", "Planning assumption"], ["Free listing technology cost", 1, "CAD / free listing / month", "Planning assumption"],
  ["Stripe variable fees", 0.036, "% of subscription", "Payments plus Billing estimate"], ["Stripe fixed fee", 0.3, "CAD / payment", "Per subscription payment"],
];
input("K30:K35"); pilot.getRange("K31:K33").format.numberFormat = money1; pilot.getRange("K34").format.numberFormat = pct; pilot.getRange("K35").format.numberFormat = money1;

section("J38:M38", "Subscription unit economics");
pilot.getRange("J39:M45").values = [["Metric", "Value", "Unit", "Notes"], ["Pilot subscription price", null, "CAD / bar / month", "Month 3 price"],
  ["Direct cost per paid bar", null, "CAD / bar / month", "Cash cost"], ["Contribution per paid bar", null, "CAD / bar / month", "Before fixed cash costs"],
  ["Contribution margin", null, "%", "Per paid subscription"], ["Month 3 free listings per paid bar", null, "ratio", "Free supply support load"],
  ["Break-even paid bars", null, "bars", "At Month 3 free-to-paid mix"]];
headers("J39:M39");
pilot.getRange("K40:K45").formulas = [["=F11"], ["=F19"], ["=K40-K41"], ["=IF(K40=0,0,K42/K40)"], ["=IF(F10=0,0,F13/F10)"], ["=G57"]];
pilot.getRange("K40:K42").format.numberFormat = money1; pilot.getRange("K43").format.numberFormat = pct; pilot.getRange("K44").format.numberFormat = "0.0x"; pilot.getRange("K45").format.numberFormat = countFmt;

pilot.getRange("J9:L13").values = [["Month", "Subscription revenue", "Cash operating profit"], ["Month 1", null, null], ["Month 2", null, null], ["Month 3", null, null], [null, null, null]];
pilot.getRange("K10:L12").formulas = [["=D12", "=D38"], ["=E12", "=E38"], ["=F12", "=F38"]]; headers("J9:L9");
pilot.getRange("K10:L12").format.numberFormat = money;
const chart = pilot.charts.add("bar", pilot.getRange("J9:L12"));
chart.title = "Toronto pilot subscription revenue and cash operating profit (CAD)"; chart.hasLegend = true; chart.yAxis = { numberFormatCode: '"C$"#,##0' }; chart.setPosition("J9", "Q25");

section("A60:H60", "Model checks");
pilot.getRange("A61:F61").values = [["Check", "Actual", "Expected", "Difference", "Tolerance", "Status"]]; headers("A61:F61");
pilot.getRange("A62:A66").values = [["Subscription revenue ties"], ["Total revenue ties"], ["Operating profit reconciles"], ["Ending cash reconciles"], ["Future revenue placeholders default to zero"]];
pilot.getRange("B62:E66").formulas = [
  ["=G12", "=SUM(D12:F12)", "=B62-C62", "=0.01"], ["=G15", "=G12+G14", "=B63-C63", "=0.01"],
  ["=G38", "=G24-G37", "=B64-C64", "=0.01"], ["=G56", "=G38-G50", "=B65-C65", "=0.01"], ["=G14+G22", "=0", "=B66-C66", "=0.01"],
];
pilot.getRange("F62:F66").formulas = [["=IF(ABS(D62)<=E62,\"OK\",\"FAIL\")"], ["=IF(ABS(D63)<=E63,\"OK\",\"FAIL\")"], ["=IF(ABS(D64)<=E64,\"OK\",\"FAIL\")"], ["=IF(ABS(D65)<=E65,\"OK\",\"FAIL\")"], ["=IF(ABS(D66)<=E66,\"OK\",\"FAIL\")"]];
pilot.getRange("B62:E66").format.numberFormat = money; pilot.getRange("F62:F66").conditionalFormats.add("containsText", { text: "OK", format: { fill: "#D7F5DF", font: { color: "#067647", bold: true } } });
pilot.getRange("F62:F66").conditionalFormats.add("containsText", { text: "FAIL", format: { fill: "#FEE4E2", font: { color: C.red, bold: true } } });

workbook.comments.setSelf({ displayName: "Outly" });
for (const [cell, text] of [
  ["D10", "Assumption: paid bar ramp of 5, 10 and 15 during the Toronto pilot | Owner: Outly | Date: 2026-07-18"],
  ["D11", "Assumption: C$129 monthly pilot subscription price | Owner: Outly | Date: 2026-07-18"],
  ["D14", "Placeholder: partner economics are not modeled. Enter revenue only after pricing is decided | Owner: Outly | Date: 2026-07-18"],
  ["D22", "Placeholder: enter any direct cash cost associated with optional other revenue | Owner: Outly | Date: 2026-07-18"],
  ["D26", "Supabase Free assumed sufficient for the Toronto pilot; update only if limits or production requirements change | Date: 2026-07-18"],
  ["D29", "Estimate for getoutly.app and included GoDaddy email; replace with actual monthly equivalent | Date: 2026-07-18"],
]) workbook.comments.addThread({ cell: pilot.getRange(cell) }, text);

pilot.freezePanes.freezeRows(9);
for (const [range, width] of [["A1:A66", 39], ["B1:B66", 22], ["C1:G66", 16], ["H1:H66", 50], ["I1:I66", 4], ["J1:J66", 32], ["K1:K66", 17], ["L1:L66", 22], ["M1:M66", 40], ["N1:Q66", 16]]) pilot.getRange(range).format.columnWidth = width;
pilot.getRange("A1:Q66").format.verticalAlignment = "center"; pilot.getRange("A1:Q66").format.wrapText = true;
pilot.getRange("H10:H40").format.rowHeight = 30; pilot.getRange("A41:H41").format.rowHeight = 30;

const inspect = await workbook.inspect({ kind: "table", range: "Toronto Pilot!A1:M66", include: "values,formulas", tableMaxRows: 66, tableMaxCols: 13 });
const errors = await workbook.inspect({ kind: "match", searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A", options: { useRegex: true, maxResults: 100 }, summary: "pilot formula error scan" });
console.log(inspect.ndjson); console.log(errors.ndjson);
const preview = await workbook.render({ sheetName: "Toronto Pilot", range: "A1:Q66", scale: 1.2, format: "png" });
await fs.writeFile(`${outputDir}/toronto_pilot.png`, new Uint8Array(await preview.arrayBuffer()));
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(`${outputDir}/Outly_Revenue_Pricing_Model.xlsx`);
console.log(`${outputDir}/Outly_Revenue_Pricing_Model.xlsx`);
