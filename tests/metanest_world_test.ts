import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can create new world",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('metanest-world', 'create-world', [
        types.ascii("Test World"),
        types.ascii("A test virtual world"),
      ], deployer.address)
    ]);
    
    // Check world creation succeeded
    block.receipts[0].result.expectOk();
    
    // Verify world data
    let worldDataBlock = chain.mineBlock([
      Tx.contractCall('metanest-world', 'get-world-data', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    let worldData = worldDataBlock.receipts[0].result.expectSome();
    assertEquals(worldData['name'], "Test World");
    assertEquals(worldData['owner'], deployer.address);
  },
});

Clarinet.test({
  name: "Test portal creation between worlds",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create two worlds
    let block = chain.mineBlock([
      Tx.contractCall('metanest-world', 'create-world', [
        types.ascii("World One"),
        types.ascii("First test world"),
      ], deployer.address),
      
      Tx.contractCall('metanest-world', 'create-world', [
        types.ascii("World Two"), 
        types.ascii("Second test world"),
      ], deployer.address)
    ]);
    
    // Create portal between worlds
    let portalBlock = chain.mineBlock([
      Tx.contractCall('metanest-world', 'create-portal', [
        types.uint(1),
        types.uint(2)
      ], deployer.address)
    ]);
    
    portalBlock.receipts[0].result.expectOk();
    
    // Verify portal exists
    let portalDataBlock = chain.mineBlock([
      Tx.contractCall('metanest-world', 'get-portal-data', [
        types.uint(1),
        types.uint(2)
      ], deployer.address)
    ]);
    
    portalDataBlock.receipts[0].result.expectSome();
  },
});