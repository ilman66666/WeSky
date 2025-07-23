import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Auth "canister:auth";
import Nat32 "mo:base/Nat32";

actor Inventory {

  type Item = {
    id: Nat;
    name: Text;
    quantity: Nat;
    addedBy: Principal;
  };

  let items = Buffer.Buffer<Item>(0);

  // Helper function to generate a unique ID based on principal and item count
  func generateId(principal: Principal, count: Nat) : Nat {
    // Convert count to Nat32 for XOR, then cast result to Nat
    return Nat32.toNat(Principal.hash(principal) ^ Nat32.fromNat(count));
  };

  public shared ({ caller }) func addItem(name: Text, quantity: Nat) : async Text {
    let access = await Auth.hasAccess(caller, "Inventory");
    if (not access) {
      return "Access denied";
    };

    let id = generateId(caller, items.size());
    items.add({
      id = id;
      name = name;
      quantity = quantity;
      addedBy = caller;
    });
    return "Item added!";
  };

  public shared query ({ caller = _ }) func listItems() : async [Item] {
    return Buffer.toArray(items);
  };

  public shared ({ caller }) func editItem(id: Nat, newName: Text, newQuantity: Nat) : async Text {
    // Find the index of the item with the given id
    var idxOpt : ?Nat = null;
    var i = 0;
    let n = items.size();
    label search while (i < n) {
      if (items.get(i).id == id) {
        idxOpt := ?i;
        break search;
      };
      i += 1;
    };
    switch (idxOpt) {
      case (?idx) {
        let item = items.get(idx);
        // Only allow editing if the caller is the one who added the item
        if (item.addedBy != caller) {
          return "Permission denied: Only the creator can edit this item.";
        };
        // Only update name and quantity, keep id and addedBy unchanged
        items.put(idx, {
          id = item.id;
          name = newName;
          quantity = newQuantity;
          addedBy = item.addedBy;
        });
        return "Item updated!";
      };
      case null {
        return "Item not found.";
      };
    }
  }
}