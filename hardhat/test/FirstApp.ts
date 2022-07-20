import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { anyValue } from '@nomicfoundation/hardhat-chai-matchers/withArgs'
import { expect } from 'chai'
import { ethers } from 'hardhat'
const { BigNumber } = ethers
describe('FirstApp', function () {
  async function deployFirstApp() {
    const FirstApp = await ethers.getContractFactory('Counter')
    const firstApp = await FirstApp.deploy()
    return { firstApp }
  }
  describe('firstApp', function () {
    it('should increase count by step 1', async function () {
      const { firstApp } = await loadFixture(deployFirstApp)
      const prevCount = await firstApp.get()
      await firstApp.inc()
      expect(await firstApp.get()).to.equal(prevCount.add(BigNumber.from(1)))
    })
    it('should revert count 0-1 overflow', async function () {
      const { firstApp } = await loadFixture(deployFirstApp)
      await expect(firstApp.dec()).to.be.revertedWithPanic(0x11)
    })
    it('should decrease count by step 1', async function () {
      const { firstApp } = await loadFixture(deployFirstApp)
      await firstApp.inc()
      await firstApp.dec()
      expect(await firstApp.get()).to.equal(BigNumber.from(0))
    })
  })
})
