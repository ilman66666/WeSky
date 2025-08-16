/**
 * @title Transaction Interface Types
 * @dev Type definitions for the Transaction module
 */
import Principal "mo:base/Principal";
import Time "mo:base/Time";

module {
  public type TransactionRecord = {
    id: Nat;                    // Transaction ID
    description: Text;          // Transaction description
    amount: Nat;                // Transaction amount
    createdBy: Principal;       // Principal who created the transaction
    timestamp: Time.Time;       // Timestamp when created
    deadline: ?Time.Time;       // Deadline payment (optional)
    updatedAt: ?Time.Time;      // Timestamp when updated (optional)
    transactionType: ?Text;     // Income or Expense (optional)
    status: ?Text;              // Active or Inactive (optional)
  };
  
  public type TransactionInterface = actor {
    addTransaction : shared (description: Text, amount: Nat, transactionType: ?Text, deadline: ?Time.Time) -> async Text;
    listTransactions : shared query () -> async [TransactionRecord];
    updateTransactionStatus : shared (id: Nat, newStatus: Text) -> async Text;
    updateTransactionType : shared (id: Nat, newType: Text) -> async Text;
    updateDescription : shared (id: Nat, newDescription: Text) -> async Text;
    updateAmount : shared (id: Nat, newAmount: Nat) -> async Text;
    updateDeadline : shared (id: Nat, newDeadline: Time.Time) -> async Text;
  };
}