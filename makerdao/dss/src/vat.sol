// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- Dai CDP database

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Vat {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        require(live == 1, "Vat/not-live");
        wards[usr] = 1;
    }

    function deny(address usr) external auth {
        require(live == 1, "Vat/not-live");
        wards[usr] = 0;
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }

    mapping(address => mapping(address => uint256)) public can;

    function hope(address usr) external {
        can[msg.sender][usr] = 1;
    }

    function nope(address usr) external {
        can[msg.sender][usr] = 0;
    }

    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    //每种抵押资产的汇总信息
    struct Ilk {
        uint256 Art; // 该资产总共的债务     [wad]
        uint256 rate; // dai的累积费率         [ray]
        uint256 spot; // 每单位抵押品允许借出的最大dai  [ray]
        uint256 line; // 该抵押品的债务上限             [rad]
        uint256 dust; // 该抵押品的债务下限            [rad]
    }
    //某个特定的vault，抵押了多少，借了多少dai，对于每个特定抵押类型的一个特定的用户而言
    struct Urn {
        uint256 ink; // 质押的抵押品量，注意和gem的余额加起来是用户的抵押品总余额  [wad]
        uint256 art; // Normalised Debt    [wad]
    }

    mapping(bytes32 => Ilk) public ilks;
    mapping(bytes32 => mapping(address => Urn)) public urns;
    //vat中记录的各种抵押资产的余额
    mapping(bytes32 => mapping(address => uint256)) public gem; // [wad]
    //vat.dai的余额
    mapping(address => uint256) public dai; // [rad]
    //系统债务某用户无抵押生成dai的总额
    mapping(address => uint256) public sin; // [rad]

    uint256 public debt; // Total Dai Issued    [rad]
    uint256 public vice; // Total Unbacked Dai  [rad]
    //总债务上限
    uint256 public Line; // Total Debt Ceiling  [rad]
    //合约是否可用
    uint256 public live; // Active Flag

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

    function mul(uint256 x, int256 y) internal pure returns (int256 z) {
        z = int256(x) * y;
        require(int256(x) >= 0);
        require(y == 0 || z / y == int256(x));
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    //添加一个新的抵押类型
    function init(bytes32 ilk) external auth {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10**27;
    }

    function file(bytes32 what, uint256 data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
    }

    function cage() external auth {
        live = 0;
    }

    // --- Fungibility ---
    //减少某个用户的抵押品余额,slip
    function slip(
        bytes32 ilk,
        address usr,
        int256 wad
    ) external auth {
        gem[ilk][usr] = add(gem[ilk][usr], wad);
    }

    //将抵押品发送给别人
    function flux(
        bytes32 ilk,
        address src,
        address dst,
        uint256 wad
    ) external {
        require(wish(src, msg.sender), "Vat/not-allowed");
        gem[ilk][src] = sub(gem[ilk][src], wad);
        gem[ilk][dst] = add(gem[ilk][dst], wad);
    }

    //将vat.dai发送给别人
    function move(
        address src,
        address dst,
        uint256 rad
    ) external {
        require(wish(src, msg.sender), "Vat/not-allowed");
        dai[src] = sub(dai[src], rad);
        dai[dst] = add(dai[dst], rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    function both(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }

    // --- CDP Manipulation ---
    //
    function frob(
        bytes32 i, //抵押资产类型
        address u, //user
        address v, //抵押物的来源地址(dink为正值则需要approve)
        address w, //借出/还入dai的地址
        int256 dink, //u抵押资产lock的改变量 >0是增加抵押量,gem余额减少，但用户lock的抵押品增加
        int256 dart //u dai的改变量 >0是增加债务
    ) external {
        //dart不是时机借出/还入的量
        // system is live
        require(live == 1, "Vat/not-live");

        Urn memory urn = urns[i][u];
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");

        urn.ink = add(urn.ink, dink);
        urn.art = add(urn.art, dart);
        ilk.Art = add(ilk.Art, dart);

        int256 dtab = mul(ilk.rate, dart);
        uint256 tab = mul(ilk.rate, urn.art);
        debt = add(debt, dtab);

        // 如dart>0即需要继续生成dai，则一定不能超过债务上限
        require(
            either(
                dart <= 0,
                both(mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)
            ),
            "Vat/ceiling-exceeded"
        );
        //但凡增加v抵押品减少u的抵押lock量即或者用u的抵押增加w的dai，那么单个u的valut总债务应该小于上限，不得小于抵押率
        require(
            either(both(dart <= 0, dink >= 0), tab <= mul(urn.ink, ilk.spot)),
            "Vat/not-safe"
        );

        // 但凡增加v抵押品减少u的抵押lock量即或者增加w的dai，那么u就应该授权给msg.sender
        require(
            either(both(dart <= 0, dink >= 0), wish(u, msg.sender)),
            "Vat/not-allowed-u"
        );
        // 抵押品的来源地址 减少v的gem，即增加u的抵押量，
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // 如果是减少w的可用dai即消除u的债务
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");
        //dink>0,用户自由的gem余额减少，但锁定urn.ink的增加
        gem[i][v] = sub(gem[i][v], dink);
        //dart>0 用户w的可用dai增加
        dai[w] = add(dai[w], dtab);

        urns[i][u] = urn;
        ilks[i] = ilk;
    }

    // --- CDP Fungibility ---
    function fork(
        bytes32 ilk,
        address src,
        address dst,
        int256 dink,
        int256 dart
    ) external {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = sub(u.ink, dink);
        u.art = sub(u.art, dart);
        v.ink = add(v.ink, dink);
        v.art = add(v.art, dart);

        uint256 utab = mul(u.art, i.rate);
        uint256 vtab = mul(v.art, i.rate);

        // both sides consent
        require(
            both(wish(src, msg.sender), wish(dst, msg.sender)),
            "Vat/not-allowed"
        );

        // both sides safe
        require(utab <= mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
    }

    // --- CDP Confiscation ---
    //清算一个vault
    function grab(
        bytes32 i,
        address u, //被清算的用户
        address v, //清算受益者，抵押品接收者
        address w, //拍卖债务的承担者
        int256 dink, //将要拍卖的锁定的抵押品
        int256 dart //债务
    ) external auth {
        //dink<0 dart<0
        //u的债务情况
        Urn storage urn = urns[i][u];
        //这个抵押资产的总的概况
        Ilk storage ilk = ilks[i];
        //锁定的抵押品减少，债务减少
        urn.ink = add(urn.ink, dink);
        urn.art = add(urn.art, dart);
        ilk.Art = add(ilk.Art, dart);

        int256 dtab = mul(ilk.rate, dart);

        gem[i][v] = sub(gem[i][v], dink);
        //w的系统债务增加
        sin[w] = sub(sin[w], dtab);
        //总的系统债务增加
        vice = sub(vice, dtab);
    }

    // --- Settlement ---
    //抵消自己未使用领取的vat.dai与自己的system debt
    function heal(uint256 rad) external {
        address u = msg.sender;
        sin[u] = sub(sin[u], rad);
        dai[u] = sub(dai[u], rad);
        vice = sub(vice, rad);
        debt = sub(debt, rad);
    }

    //管理员无成本增加system debt，并生成vat.dai
    function suck(
        address u,
        address v,
        uint256 rad
    ) external auth {
        sin[u] = add(sin[u], rad);
        dai[v] = add(dai[v], rad);
        vice = add(vice, rad);
        debt = add(debt, rad);
    }

    // --- Rates ---
    //有jug合约调用，1.更新ilk的rate累积值，增加vow的盈余，增加总债务
    function fold(
        bytes32 i,
        address u,
        int256 rate //增加或减少的费率
    ) external auth {
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];
        ilk.rate = add(ilk.rate, rate);
        int256 rad = mul(ilk.Art, rate);
        dai[u] = add(dai[u], rad);
        debt = add(debt, rad);
    }
}
