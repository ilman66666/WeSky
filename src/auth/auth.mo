import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

actor Auth {

  stable var subscriptionsData : [(Principal, [Text])] = [];

  var subscriptions = HashMap.HashMap<Principal, [Text]>(0, Principal.equal, Principal.hash);

  system func preupgrade() {
    subscriptionsData := Iter.toArray(subscriptions.entries());
  };

  system func postupgrade() {
    subscriptions := HashMap.HashMap<Principal, [Text]>(subscriptionsData.size(), Principal.equal, Principal.hash);
    for ((k, v) in subscriptionsData.vals()) {
      subscriptions.put(k, v);
    };
  };

  public func subscribeUser(user: Principal, modules: [Text]) : async () {
    subscriptions.put(user, modules);
  };

  public query func hasAccess(user: Principal, modul: Text) : async Bool {
    switch (subscriptions.get(user)) {
      case (?mods) {
        return Array.find<Text>(mods, func(m) { m == modul }) != null;
      };
      case null {
        return false;
      };
    }
  };
}