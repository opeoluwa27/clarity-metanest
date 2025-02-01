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
    assertEquals(worldData['activity-count'], types.uint(0));
    assertEquals(worldData['total-rewards'], types.uint(0));
  },
});

Clarinet.test({
  name: "Test creating and participating in world activities",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const participant = accounts.get('wallet_1')!;
    
    // Create world
    let block = chain.mineBlock([
      Tx.contractCall('metanest-world', 'create-world', [
        types.ascii("Activity World"),
        types.ascii("A world with activities"),
      ], deployer.address)
    ]);
    
    // Create activity
    let activityBlock = chain.mineBlock([
      Tx.contractCall('metanest-world', 'create-activity', [
        types.uint(1),
        types.ascii("Test Activity"),
        types.ascii("An activity with rewards"),
        types.uint(100)
      ], deployer.address)
    ]);
    
    activityBlock.receipts[0].result.expectOk();
    
    // Participate in activity
    let participateBlock = chain.mineBlock([
      Tx.contractCall('metanest-world', 'participate-activity', [
        types.uint(1),
        types.uint(1)
      ], participant.address)
    ]);
    
    participateBlock.receipts[0].result.expectOk();
    
    // Verify activity data
    let activityDataBlock = chain.mineBlock([
      Tx.contractCall('metanest-world', 'get-activity-data', [
        types.uint(1),
        types.uint(1)
      ], deployer.address)
    ]);
    
    let activityData = activityDataBlock.receipts[0].result.expectSome();
    assertEquals(activityData['participants'], types.uint(1));
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
