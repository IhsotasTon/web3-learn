import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs'
import { expect } from 'chai'
import { ethers } from 'hardhat'
describe('HelloWorld', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshopt in every test.
  async function deployHelloWorld() {
    const HelloWorld = await ethers.getContractFactory('HelloWorld')
    const hello = await HelloWorld.deploy()

    return { hello }
  }
  describe('HelloWorld', function () {
    it('should set the correct greet string', async function () {
      const { hello } = await loadFixture(deployHelloWorld)
      expect(await hello.greet()).to.equal('HelloWorld')
    })
  })
})
