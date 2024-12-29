import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can create and fund escrow agreement",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const buyer = accounts.get('wallet_1')!;
        const seller = accounts.get('wallet_2')!;
        
        // Create escrow
        let block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'create-escrow', [
                types.principal(seller.address),
                types.uint(1000),
                types.uint(100)
            ], buyer.address)
        ]);
        block.receipts[0].result.expectOk().expectUint(1);
        
        // Fund escrow
        block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'fund-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
        
        // Verify escrow status
        block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'get-escrow', [
                types.uint(1)
            ], deployer.address)
        ]);
        const escrow = block.receipts[0].result.expectSome().expectTuple();
        assertEquals(escrow.status, types.uint(1));
    }
});

Clarinet.test({
    name: "Can release funds to seller",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const buyer = accounts.get('wallet_1')!;
        const seller = accounts.get('wallet_2')!;
        
        // Setup: Create and fund escrow
        let block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'create-escrow', [
                types.principal(seller.address),
                types.uint(1000),
                types.uint(100)
            ], buyer.address),
            Tx.contractCall('quantum_vault', 'fund-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        // Release funds
        block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'release-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can cancel escrow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const buyer = accounts.get('wallet_1')!;
        const seller = accounts.get('wallet_2')!;
        
        // Setup: Create and fund escrow
        let block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'create-escrow', [
                types.principal(seller.address),
                types.uint(1000),
                types.uint(100)
            ], buyer.address),
            Tx.contractCall('quantum_vault', 'fund-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        // Cancel escrow
        block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'cancel-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can raise dispute",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const buyer = accounts.get('wallet_1')!;
        const seller = accounts.get('wallet_2')!;
        
        // Setup: Create and fund escrow
        let block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'create-escrow', [
                types.principal(seller.address),
                types.uint(1000),
                types.uint(100)
            ], buyer.address),
            Tx.contractCall('quantum_vault', 'fund-escrow', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        // Raise dispute
        block = chain.mineBlock([
            Tx.contractCall('quantum_vault', 'raise-dispute', [
                types.uint(1)
            ], seller.address)
        ]);
        block.receipts[0].result.expectOk().expectBool(true);
    }
});