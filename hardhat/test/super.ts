import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs'
import { expect } from 'chai'
import { ethers } from 'hardhat'
describe('Super', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshopt in every test.
  async function deploySuper() {
    const D = await ethers.getContractFactory('D')
    const d = await D.deploy()
    return { d }
  }
  describe('D', function () {
    it('test super => storage', async function () {
      const { d } = await loadFixture(deploySuper)
      await d.bar()
      // expect(await stora.x()).to.equal('D')
    })
  })
})
