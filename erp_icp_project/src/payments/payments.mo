import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Auth "canister:auth";

actor Payments {

    // Structure representing a payment contract
    type PaymentContract = {
        id : Nat;
        recipient : Principal;
        description : Text;
        amount : Nat;
        dueDate : Time.Time; // nanoseconds
        isPaid : Bool;
        createdAt : Time.Time;
        creator : Principal; // Added field to track who created the contract
    };

    let contracts = Buffer.Buffer<PaymentContract>(0);

    var nextId : Nat = 1;

    // Access control helper
    func requireAccess(caller : Principal, feature : Text) : async Bool {
        let has = await Auth.hasAccess(caller, feature);
        return has;
    };

    // Add a new payment contract
    public shared ({ caller }) func createContract(
        recipient : Principal,
        description : Text,
        amount : Nat,
        dueDate : Time.Time,
    ) : async Text {
        let allowed = await requireAccess(caller, "Payments");
        if (not allowed) {
            return "Access denied.";
        };

        let contract : PaymentContract = {
            id = nextId;
            recipient = recipient;
            description = description;
            amount = amount;
            dueDate = dueDate;
            isPaid = false;
            createdAt = Time.now();
            creator = caller; // Store the caller's principal as the creator
        };

        contracts.add(contract);
        nextId += 1;
        return "Contract created successfully.";
    };

    // Process payment by marking it as paid (simulation)
    public shared ({ caller }) func markAsPaid(id : Nat) : async Text {
        let allowed = await requireAccess(caller, "Payments");
        if (not allowed) {
            return "Access denied.";
        };

        var found = false;
        var i = 0;
        let size = contracts.size();

        while (i < size) {
            switch (contracts.get(i)) {
                case (contract) {
                    if (contract.id == id) {
                        if (contract.isPaid) {
                            return "Already paid.";
                        };

                        contracts.put(
                            i,
                            {
                                id = contract.id;
                                recipient = contract.recipient;
                                description = contract.description;
                                amount = contract.amount;
                                dueDate = contract.dueDate;
                                isPaid = true;
                                createdAt = contract.createdAt;
                                creator = contract.creator; // Preserve the creator information
                            }
                        );

                        found := true;
                        return "Payment marked as completed.";
                    };
                };
            };
            i += 1;
        };

        return "Contract not found.";
    };

    // List all contracts
    public query func listContracts() : async [PaymentContract] {
        return Buffer.toArray(contracts);
    };

    // List unpaid contracts only
    public query func listUnpaidContracts() : async [PaymentContract] {
        let filtered = Buffer.Buffer<PaymentContract>(0);
        for (c in contracts.vals()) {
            if (not c.isPaid) {
                filtered.add(c);
            };
        };
        return Buffer.toArray(filtered);
    };
};
