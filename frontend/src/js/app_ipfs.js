AppIPFS = {
    IpfsNode: null,
    selectedFile: "",
    selectedFileCID: null,
    selectedFileUploaded: false,
    selectedJSON: null,

    init: async () => {
        if(AppIPFS.IpfsNode === null || AppIPFS.IpfsNode === undefined) {
            AppIPFS.IpfsNode = await Ipfs.create();
        }
    }
}