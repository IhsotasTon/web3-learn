import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs'
import { expect } from 'chai'
import { ethers } from 'hardhat'
describe('Storage', function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshopt in every test.
  async function deployStorage() {
    const Storage = await ethers.getContractFactory('Storage')
    const stora = await Storage.deploy()
    return { stora }
  }
  describe('HelloWorld', function () {
    it('test storage => storage', async function () {
      const { stora } = await loadFixture(deployStorage)
      await stora.local2local()
      console.log(await stora.getX())
      // console.log(await stora.getY())
      // expect(await stora.x()).to.equal('HelloWorld')
    })
  })
})
