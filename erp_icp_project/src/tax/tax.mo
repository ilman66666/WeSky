import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Auth "canister:auth";

actor TaxReporter {

  // Define the structure of a transaction
  // This can be income, expense, or any other financial action
  type Transaction = {
    id : Nat;
    timestamp : Int;
    action : Text;
    productName : Text;
    quantity : Nat;
    performedBy : Principal;
    details : Text;
  };

  type FinancialSummary = {
    totalIncome : Nat;
    totalExpenses : Nat;
    netProfit : Int;
    taxDue : Nat;
  };

  type TaxReport = {
    period : Text; // e.g., "2025-07"
    summary : FinancialSummary;
    generatedAt : Time.Time;
  };

  // Storage
  let reports = Buffer.Buffer<TaxReport>(0);

  // Safe Int -> Nat converter
  func toNat(i : Int) : Nat {
    if (i < 0) { 0 } else { Int.abs(i) };
  };

  public shared ({ caller }) func generateMonthlyTaxReport(
    transactions : [Transaction],
    year : Nat,
    month : Nat,
  ) : async Text {
    let access = await Auth.hasAccess(caller, "Tax");
    if (not access) {
      return "Access denied";
    };

    var income : Nat = 0;
    var expenses : Nat = 0;

    for (txn in transactions.vals()) {
      // We can’t extract date parts directly from Time.Time — skip filtering if needed
      // If you need to filter by year/month, add that info to the transaction struct
      if (txn.action == "income") {
        income += txn.quantity;
      } else if (txn.action == "expense") {
        expenses += txn.quantity;
      };
    };

    let netProfit : Int = toNat(income) - toNat(expenses);
    let taxRate : Nat = 10;
    let taxDue : Nat = toNat((netProfit * taxRate) / 100);

    let report : TaxReport = {
      period = Nat.toText(year) # "-" # Nat.toText(month);
      summary = {
        totalIncome = income;
        totalExpenses = expenses;
        netProfit = netProfit;
        taxDue = taxDue;
      };
      generatedAt = Time.now();
    };

    reports.add(report);
    return "Tax report generated and stored.";
  };

  public query func listReports() : async [TaxReport] {
    return Buffer.toArray(reports);
  };

  public query func latestReport() : async ?TaxReport {
    if (reports.size() == 0) {
      return null;
    };
    return ?reports.get(reports.size() - 1);
  };
};
