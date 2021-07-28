var web3;

App = {
    web3Provider: null,
    contracts: {},

    init: function() {
        return App.initWeb3();
    },

    initWeb3: function() {
        getWeb3().then((w3) => {
            web3 = w3;
            web3.eth.getBlockNumber(console.log);
            console.log("Ket noi thanh cong");
        }).catch((err) => console.log("Khong tim thay web3"));

        // console.log(web3);

        if(typeof web3 !== "undefined") {
            App.web3Provider = window.ethereum;
            // console.log(window.ethereum);

            web3 = new Web3(window.ethereum);
        }
        else {
            web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:7545"));
            App.web3Provider = web3.currentProvider;
        }
        return App.initContract();
    },

    initContract: function() {
        // $.getJSON("js/DuBaoTuongLai.json", (contract) => {
        //     var ABI = web3.eth.contract(contract.abi);
        //     App.contracts.DuBaoTuongLai = ABI.at(contract.networks[window.ethereum.networkVersion].address); // Connecto to Rinkeby testnet - ChainID: 4
        //     console.log(`Contract Address: ${App.contracts.DuBaoTuongLai.address}`);
        //     console.log(App.contracts.DuBaoTuongLai);
        //     App.render();
        // });
        $.getJSON("contracts/NginNFT.json", (nft) => {
            App.contracts.NginNFT = web3.eth.contract(nft.abi).at(nft.networks[window.ethereum.networkVersion].address); // Connect to Rinkeby testnet - ChainID: 4
            console.log(`NginNFT Address: ${App.contracts.NginNFT.address}`);
            console.log(App.contracts.NginNFT);
            App.render();
        })
    },

    render: function() {
        console.log(App);
        web3.eth.getCoinbase(function(error, account) {
            if(error === null) {
                App.account = account;
                console.log(`Host account: ${App.account}`);
            }
        });
    }


};

$(function() {
    $(window).on('load', function() {
        App.init();
    });
});