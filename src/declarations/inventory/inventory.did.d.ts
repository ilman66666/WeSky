import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export interface Item {
  'id' : bigint,
  'name' : string,
  'addedBy' : Principal,
  'quantity' : bigint,
}
export interface _SERVICE {
  'addItem' : ActorMethod<[string, bigint], string>,
  'editItem' : ActorMethod<[bigint, string, bigint], string>,
  'listItems' : ActorMethod<[], Array<Item>>,
}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
