AppIPFS = {
    IpfsNode: null,
    selectedFile: "",
    selectedFileCID: null,

    init: async () => {
        if(AppIPFS.IpfsNode === null || AppIPFS.IpfsNode === undefined) {
            AppIPFS.IpfsNode = await Ipfs.create();
        }
    }
}