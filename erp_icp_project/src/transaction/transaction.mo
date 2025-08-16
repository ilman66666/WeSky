/**
 * @title Transaction Management System
 * @dev This module handles financial transactions for the ERP system
 * @notice Provides functionality to create, list, edit, and manage transaction records
 */
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Auth "canister:auth";
import Nat32 "mo:base/Nat32";
import Time "mo:base/Time";


actor class Transaction() : async {
  // Interface methods
  addTransaction : shared (description: Text, amount: Nat, transactionType: ?Text, deadline: ?Time.Time) -> async Text;
  listTransactions : shared query () -> async [TransactionRecord];
  updateTransactionStatus : shared (id: Nat, newStatus: Text) -> async Text;
  updateTransactionType : shared (id: Nat, newType: Text) -> async Text;
  updateDescription : shared (id: Nat, newDescription: Text) -> async Text;
  updateAmount : shared (id: Nat, newAmount: Nat) -> async Text;
  updateDeadline : shared (id: Nat, newDeadline: Time.Time) -> async Text;
} 

{

  /**
   * @dev Structure for storing transaction information
   * @param id Unique identifier for the transaction
   * @param description Text description of the transaction
   * @param amount Numeric amount of the transaction
   * @param createdBy Principal ID of the transaction creator
   * @param timestamp Creation time in nanoseconds since 1970-01-01
   * @param deadline Optional due date for the transaction
   * @param updatedAt Optional timestamp of last update
   * @param transactionType Optional classification ("Income" or "Expense")
   * @param status Optional status ("Active" or "Inactive")
   */
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

  // Buffer to store all transactions
  let transactions = Buffer.Buffer<TransactionRecord>(0);

  /**
   * @dev Generates a unique ID for a transaction
   * @param principal The principal identifier of the creator
   * @param count The current count of transactions
   * @return A unique natural number ID
   */
  func generateId(principal: Principal, count: Nat) : Nat {
    return Nat32.toNat(Principal.hash(principal) ^ Nat32.fromNat(count));
  };

  /**
   * @dev Creates a new transaction record
   * @param description Text description of the transaction
   * @param amount Numeric amount of the transaction
   * @param transactionType Optional type ("Income" or "Expense")
   * @param deadline Optional due date in nanoseconds
   * @return Text message indicating success or failure
   * @notice Requires "Transaction" access permission
   * @usage 
   * ```
   * // Basic usage
   * let result = await Transaction.addTransaction("Office supplies", 500, null, null);
   * 
   * // With all parameters
   * let result = await Transaction.addTransaction("Office rent", 2000, ?"Expense", ?timestamp);
   * ```
   */
  public shared ({ caller }) func addTransaction(description: Text, amount: Nat, transactionType: ?Text, deadline: ?Time.Time) : async Text {
    let access = await Auth.hasAccess(caller, "Transaction");
    if (not access) {
      return "Access denied";
    };

    let id = generateId(caller, transactions.size());
    transactions.add({
      id = id;
      description = description;
      amount = amount;
      deadline = deadline;
      createdBy = caller;
      timestamp = Time.now();
      updatedAt = null;
      transactionType = transactionType;
      status = ?"Active";
    });
    return "Transaction added!";
  };

  /**
   * @dev Retrieves all transactions
   * @return Array of all transaction records
   * @notice This is a query function and does not update state
   */
  public shared query ({ caller = _ }) func listTransactions() : async [TransactionRecord] {
    return Buffer.toArray(transactions);
  };
  
  /**
   * @dev Updates the status of a transaction
   * @param id The unique identifier of the transaction
   * @param newStatus The new status value (e.g., "Active", "Inactive", "Completed")
   * @return Text message indicating success or failure
   * @notice Only the creator of the transaction can change its status
   * @usage 
   * ```
   * // Mark as inactive
   * let result = await Transaction.updateTransactionStatus(123, "Inactive");
   * 
   * // Mark as completed
   * let result = await Transaction.updateTransactionStatus(123, "Completed");
   * ```
   */
  public shared ({ caller }) func updateTransactionStatus(id: Nat, newStatus: Text) : async Text {
    var idxOpt : ?Nat = null;
    var i = 0;
    let n = transactions.size();
    label search while (i < n) {
      if (transactions.get(i).id == id) {
        idxOpt := ?i;
        break search;
      };
      i += 1;
    };
    switch (idxOpt) {
      case (?idx) {
        let transaction = transactions.get(idx);
        if (transaction.createdBy != caller) {
          return "Permission denied: Only the creator can change the status.";
        };
        transactions.put(idx, {
          id = transaction.id;
          description = transaction.description;
          amount = transaction.amount;
          deadline = transaction.deadline;
          createdBy = transaction.createdBy;
          timestamp = transaction.timestamp;
          updatedAt = ?Time.now();
          transactionType = transaction.transactionType;
          status = ?newStatus;
        });
        return "Transaction status updated!";
      };
      case null {
        return "Transaction not found.";
      };
    }
  };
  
  /**
   * @dev Updates the transaction type of a transaction
   * @param id The unique identifier of the transaction
   * @param newType The new transaction type (e.g., "Income", "Expense")
   * @return Text message indicating success or failure
   * @notice Only the creator of the transaction can change its type
   * @usage 
   * ```
   * // Change to Income type
   * let result = await Transaction.updateTransactionType(123, "Income");
   * 
   * // Change to Expense type
   * let result = await Transaction.updateTransactionType(123, "Expense");
   * ```
   */
  public shared ({ caller }) func updateTransactionType(id: Nat, newType: Text) : async Text {
    var idxOpt : ?Nat = null;
    var i = 0;
    let n = transactions.size();
    label search while (i < n) {
      if (transactions.get(i).id == id) {
        idxOpt := ?i;
        break search;
      };
      i += 1;
    };
    switch (idxOpt) {
      case (?idx) {
        let transaction = transactions.get(idx);
        if (transaction.createdBy != caller) {
          return "Permission denied: Only the creator can change the transaction type.";
        };
        transactions.put(idx, {
          id = transaction.id;
          description = transaction.description;
          amount = transaction.amount;
          deadline = transaction.deadline;
          createdBy = transaction.createdBy;
          timestamp = transaction.timestamp;
          updatedAt = ?Time.now();
          transactionType = ?newType;
          status = transaction.status;
        });
        return "Transaction type updated!";
      };
      case null {
        return "Transaction not found.";
      };
    }
  };
  
  /**
   * @dev Updates only the description of a transaction
   * @param id The unique identifier of the transaction
   * @param newDescription The new description text
   * @return Text message indicating success or failure
   * @notice Only the creator of the transaction can update the description
   */
  public shared ({ caller }) func updateDescription(id: Nat, newDescription: Text) : async Text {
    var idxOpt : ?Nat = null;
    var i = 0;
    let n = transactions.size();
    label search while (i < n) {
      if (transactions.get(i).id == id) {
        idxOpt := ?i;
        break search;
      };
      i += 1;
    };
    switch (idxOpt) {
      case (?idx) {
        let transaction = transactions.get(idx);
        if (transaction.createdBy != caller) {
          return "Permission denied: Only the creator can update the description.";
        };
        transactions.put(idx, {
          id = transaction.id;
          description = newDescription;
          amount = transaction.amount;
          deadline = transaction.deadline;
          createdBy = transaction.createdBy;
          timestamp = transaction.timestamp;
          updatedAt = ?Time.now();
          transactionType = transaction.transactionType;
          status = transaction.status;
        });
        return "Description updated!";
      };
      case null {
        return "Transaction not found.";
      };
    }
  };
  
  /**
   * @dev Updates only the amount of a transaction
   * @param id The unique identifier of the transaction
   * @param newAmount The new transaction amount
   * @return Text message indicating success or failure
   * @notice Only the creator of the transaction can update the amount
   */
  public shared ({ caller }) func updateAmount(id: Nat, newAmount: Nat) : async Text {
    var idxOpt : ?Nat = null;
    var i = 0;
    let n = transactions.size();
    label search while (i < n) {
      if (transactions.get(i).id == id) {
        idxOpt := ?i;
        break search;
      };
      i += 1;
    };
    switch (idxOpt) {
      case (?idx) {
        let transaction = transactions.get(idx);
        if (transaction.createdBy != caller) {
          return "Permission denied: Only the creator can update the amount.";
        };
        transactions.put(idx, {
          id = transaction.id;
          description = transaction.description;
          amount = newAmount;
          deadline = transaction.deadline;
          createdBy = transaction.createdBy;
          timestamp = transaction.timestamp;
          updatedAt = ?Time.now();
          transactionType = transaction.transactionType;
          status = transaction.status;
        });
        return "Amount updated!";
      };
      case null {
        return "Transaction not found.";
      };
    }
  };
  
  /**
   * @dev Updates only the deadline of a transaction
   * @param id The unique identifier of the transaction
   * @param newDeadline The new deadline timestamp
   * @return Text message indicating success or failure
   * @notice Only the creator of the transaction can update the deadline
   */
  public shared ({ caller }) func updateDeadline(id: Nat, newDeadline: Time.Time) : async Text {
    var idxOpt : ?Nat = null;
    var i = 0;
    let n = transactions.size();
    label search while (i < n) {
      if (transactions.get(i).id == id) {
        idxOpt := ?i;
        break search;
      };
      i += 1;
    };
    switch (idxOpt) {
      case (?idx) {
        let transaction = transactions.get(idx);
        if (transaction.createdBy != caller) {
          return "Permission denied: Only the creator can update the deadline.";
        };
        transactions.put(idx, {
          id = transaction.id;
          description = transaction.description;
          amount = transaction.amount;
          deadline = ?newDeadline;
          createdBy = transaction.createdBy;
          timestamp = transaction.timestamp;
          updatedAt = ?Time.now();
          transactionType = transaction.transactionType;
          status = transaction.status;
        });
        return "Deadline updated!";
      };
      case null {
        return "Transaction not found.";
      };
    }
  };
}
