export const idlFactory = ({ IDL }) => {
  const Item = IDL.Record({
    'id' : IDL.Nat,
    'name' : IDL.Text,
    'addedBy' : IDL.Principal,
    'quantity' : IDL.Nat,
  });
  return IDL.Service({
    'addItem' : IDL.Func([IDL.Text, IDL.Nat], [IDL.Text], []),
    'editItem' : IDL.Func([IDL.Nat, IDL.Text, IDL.Nat], [IDL.Text], []),
    'listItems' : IDL.Func([], [IDL.Vec(Item)], ['query']),
  });
};
export const init = ({ IDL }) => { return []; };
