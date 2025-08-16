export const idlFactory = ({ IDL }) => {
  return IDL.Service({
    'hasAccess' : IDL.Func([IDL.Principal, IDL.Text], [IDL.Bool], ['query']),
    'subscribeUser' : IDL.Func([IDL.Principal, IDL.Vec(IDL.Text)], [], []),
  });
};
export const init = ({ IDL }) => { return []; };
