// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract Marketplace is ERC721Holder {
    
    enum enLoaiKho{ KhoTien, KhoNFT}
    
    IERC20 public KhoTien;
    
    IERC721 public KhoNFT;
    
    address NguoiTaoContract;
    
    enum enTrangThaiHopDong{ DangBan, DaBan, HuyBan}
    
    struct HopDongMuaBan {
        address     NguoiMua;
        address     NguoiBan;
        
        uint        tokenId;
        uint        MaHopDong;
        uint        TienHang;
        uint        TienNguoiMuaGuiVao;
        
        enTrangThaiHopDong TrangThaiHopDong;
    }
    
    uint public TongSoHopDong;
    
    mapping(uint => HopDongMuaBan) public DanhSachHopDongMuaBan;
    
    mapping(address => uint[]) public DanhSachHopDongCuaNguoiBan;
 
    uint public TongSoPhien;
 
    enum TrangThaiDauGia{ ChoPhepMuaLuon, TiepTucDauGia}
    struct PhienDauGia {
        address     NguoiBan;
        address     NguoiDatCuoi;
         
        uint        tokenId;
        uint        MaPhien;
        uint        GiaKhoiDiem;
        uint        GiaBanLuon;
        uint        BuocGia;
        uint        GiaCuoiCung;
        uint        ThoiGianBatDau;
        uint        ThoiGianKetThuc;
         
        bool        HoatDong; // true: phien dau gia dang hoat dong, false: phien ket thuc
        TrangThaiDauGia enTrangThaiDauGia;
    }
    
    mapping(uint => PhienDauGia) public DanhSachTatCaCacPhienDauGia; //MaPhien=>Phien
     
    mapping(address => uint[]) public DanhSachPhienDauGiaSoHuu;
     
    mapping(address => uint[]) public DanhSachPhienDauGiaThamGia;
    
    constructor(address _KhoTien, address _KhoNFT) {
        KhoTien = IERC20(_KhoTien);
        KhoNFT = IERC721(_KhoNFT);
        NguoiTaoContract = msg.sender;
    }
    
    event TaoPhienDauGiaThanhCong(uint MaPhien);
    event DauGiaThanhCong();
    event MuaThanhCong(uint tokenId);
    event KetThucPhienDauGiaThanhCong(uint MaPhien, uint TienDauGiaCuoiCung);
    event NhanTienDauGiaThanhCong(uint TienDauGiaCuoiCung);
    event TaoHopDongMuaBanThanhCong(uint _MaPhien);
    event MuaHangThanhCong(uint tokenId, uint TienHang);
    event HuyBanHangThanhCong(uint MaHopDong);
    event DoiKhoTienThanhCong(address adDiaChiKhoTien);
    event DoiKhoNFTThanhCong(address adDiaChiKhoTien);
    event DaHuyPhienDauGia(uint MaPhien);

    modifier KiemTraPhienTonTai(uint _MaPhien) {
        require(DanhSachTatCaCacPhienDauGia[_MaPhien].MaPhien == _MaPhien);
        _;
    }
    
    modifier KiemTraHopDongTonTai(uint _MaHopDong){
        require(DanhSachHopDongMuaBan[_MaHopDong].MaHopDong == _MaHopDong);
        _;
    }
    
    modifier KiemTraNguoiTaoContractGoiHam(){
        require(msg.sender == NguoiTaoContract, "Ban khong co quyen goi ham");
        _;
    }
    
    function ChuyenDiaChiKho(enLoaiKho loaiKho, address adDiaChiKho) public KiemTraNguoiTaoContractGoiHam(){
        require(loaiKho <= enLoaiKho.KhoNFT, "Loai kho khong hop le");
        require(KhoNFT.balanceOf(address(this)) == 0, "Contract van dang giu 1 luong token. Hay tra token roi moi chuyen dia chi kho");
        if(loaiKho == enLoaiKho.KhoTien){
            KhoTien = IERC20(adDiaChiKho);
            emit DoiKhoTienThanhCong(adDiaChiKho);
        }
        if(loaiKho == enLoaiKho.KhoNFT){
            KhoNFT = IERC721(adDiaChiKho);
            emit DoiKhoNFTThanhCong(adDiaChiKho);
        }
    }
    
    function KiemTraTokenIdDaCoTrongPhienDauGiaHoatDong(uint _tokenId) private view returns(bool) {
        for(uint i = 1; i <= TongSoPhien; i++){
            PhienDauGia memory objPhien = DanhSachTatCaCacPhienDauGia[i];
            if(_tokenId == objPhien.tokenId && objPhien.HoatDong == true){
                return true;
            }
        }
        return false;
    }
    
    function KiemTraTokenIdDaCoTrongHopDongMuaBanHoatDong(uint _tokenId) private view returns(bool) {
        for(uint i = 1; i <= TongSoHopDong; i++){
            HopDongMuaBan memory objPhien = DanhSachHopDongMuaBan[i];
            if(_tokenId == objPhien.tokenId && objPhien.TrangThaiHopDong == enTrangThaiHopDong.DangBan){
                return true;
            }
        }
        return false;
    }
    
    //Dau gia
    function TaoPhienDauGia(
        uint _tokenId,
        uint _GiaKhoiDiem,
        uint _GiaBanLuon,
        uint _BuocGia,
        uint _ThoiGianBatDau,
        uint _ThoiGianKetThuc) public {
        //Kiem tra ton tai cua tokenId
        require(_tokenId >= 0 && KhoNFT.ownerOf(_tokenId) != address(0), "Token id khong ton tai");
        //Kiem tra xem tokenId nay co dang dau gia tai phien khac hay khong?
        require(KiemTraTokenIdDaCoTrongPhienDauGiaHoatDong(_tokenId) == false, "Token nay dang duoc dau gia tai phien khac");
        //Kiem tra xem tokenId nay co dang ban tai HopDongMuaBan khac hay khong?
        require(KiemTraTokenIdDaCoTrongHopDongMuaBanHoatDong(_tokenId) == false, "Token nay dang duoc ban tai hop dong khac");
        //Kiem tra Gia Tien Nhap Vao
        require(_GiaKhoiDiem >= 0, "Gia khoi diem khong hop le");
        require(_GiaBanLuon >= 0, "Gia ban luon khong hop le");
        require(_BuocGia > 0, "Buoc gia khong hop le");
        require(_ThoiGianBatDau < _ThoiGianKetThuc, "Thoi gian bat dau phai truoc thoi gian ket thuc");
        require(_ThoiGianKetThuc > block.timestamp, "Thoi gian ket thuc phien khong hop le");
        
        TongSoPhien++;
        uint _MaPhien = TongSoPhien;
        
        //Tao phien dua vao mapping DanhSachTatCaCacPhienDauGia
        DanhSachTatCaCacPhienDauGia[_MaPhien] = PhienDauGia({
                                            NguoiBan: msg.sender,
                                            NguoiDatCuoi: address(0),
                                            tokenId: _tokenId,
                                            MaPhien: _MaPhien,
                                            GiaKhoiDiem: _GiaKhoiDiem,
                                            GiaBanLuon: _GiaBanLuon,
                                            BuocGia: _BuocGia,
                                            GiaCuoiCung: _GiaKhoiDiem,
                                            ThoiGianBatDau: _ThoiGianBatDau,
                                            ThoiGianKetThuc: _ThoiGianKetThuc,
                                            HoatDong: true,
                                            enTrangThaiDauGia: _GiaBanLuon == 0 ? TrangThaiDauGia.TiepTucDauGia : TrangThaiDauGia.ChoPhepMuaLuon
                                            });
        
        //Chuyen token vao contract
        KhoNFT.safeTransferFrom(msg.sender, address(this), _tokenId); 
        
        //Them phien dau gia vao danh sach cua nguoi tao
        DanhSachPhienDauGiaSoHuu[msg.sender].push(_MaPhien);
        
        emit TaoPhienDauGiaThanhCong(_MaPhien);
    }
    
    function KiemTraNguoiThamGiaDaCoTrongPhien(uint _MaPhien, address _NguoiThamGia) private view KiemTraPhienTonTai(_MaPhien) returns(bool){
        uint[] memory DanhSachMaPhienNguoiThamGia = DanhSachPhienDauGiaThamGia[_NguoiThamGia];
        for(uint i = 0; i < DanhSachMaPhienNguoiThamGia.length; i++){
            if(_MaPhien == DanhSachMaPhienNguoiThamGia[i])
                return true;
        }
        return false;
    }

    //Trc do phai approve so tien cua nguoi goi cho contract
    function DauGia(uint _MaPhien, uint _GiaTienDauGia) public KiemTraPhienTonTai(_MaPhien) {
        PhienDauGia storage objPhien = DanhSachTatCaCacPhienDauGia[_MaPhien];
        
        //Kiem tra thoi gian ket thuc va trang thai hoat dong
        require(block.timestamp < objPhien.ThoiGianKetThuc, "Phien dau gia da qua thoi gian ket thuc");
        require(objPhien.HoatDong == true, "Phien dau gia da ket thuc");
        
        //Kiem tra NguoiBan co phai la msg.sender
        require(msg.sender != objPhien.NguoiBan, "Nguoi ban khong co quyen dau gia");
        
        //Kiem tra NguoiDatCuoi co phai la msg.sender?
        require(msg.sender != objPhien.NguoiDatCuoi, "Ban dang la nguoi dau gia cuoi cung");
        
        //Kiem tra so tien dau gia
        require(_GiaTienDauGia >= (objPhien.GiaCuoiCung + objPhien.BuocGia), "So tien dau gia khong hop le");
        
        //KiemTra trang thai dau gia cua phien
        if(objPhien.enTrangThaiDauGia == TrangThaiDauGia.ChoPhepMuaLuon){
            //Neu so tien dau gia >= gia ban luon thi doi TrangThaiDauGia
            if(_GiaTienDauGia >= objPhien.GiaBanLuon){
                objPhien.enTrangThaiDauGia = TrangThaiDauGia.TiepTucDauGia;
            }
        } 
        
        //Chuyen tien vao contract
        KhoTien.transferFrom(msg.sender, address(this), _GiaTienDauGia * (1 ether));
        
        //ktra co phai nguoi dat dau tien hay k
        if(objPhien.NguoiDatCuoi != address(0)){
            //Tra Tien Cho NguoiDatCuoi hien tai
            KhoTien.transfer(objPhien.NguoiDatCuoi, objPhien.GiaCuoiCung * (1 ether));
        }
        
        if(KiemTraNguoiThamGiaDaCoTrongPhien(_MaPhien,msg.sender) == false){
            DanhSachPhienDauGiaThamGia[msg.sender].push(_MaPhien);
        }
        
        //Set GiaCuoiCung va NguoiDatCuoi cho NguoiDatCuoi
        objPhien.GiaCuoiCung = _GiaTienDauGia;
        objPhien.NguoiDatCuoi = msg.sender;
        
        emit DauGiaThanhCong();
    }
        
    function MuaLuonPhienDauGia(uint _MaPhien, uint _SoTienMuaLuon) public KiemTraPhienTonTai(_MaPhien) {
        PhienDauGia storage objPhien = DanhSachTatCaCacPhienDauGia[_MaPhien];
        
        //Kiem tra NguoiBan co phai la msg.sender
        require(msg.sender != objPhien.NguoiBan, "Nguoi ban khong co quyen mua luon");
        
        //KiemTra trang thai dau gia cua phien
        require(objPhien.enTrangThaiDauGia == TrangThaiDauGia.ChoPhepMuaLuon, "Phien dau gia khong cho phep mua luon"); 
        
        //Kiem tra thoi gian ket thuc va trang thai hoat dong
        require(block.timestamp < objPhien.ThoiGianKetThuc, "Phien dau gia da qua thoi gian ket thuc");
        require(objPhien.HoatDong == true, "Phien dau gia da ket thuc");
        
        //Kiem tra SoTienMuaLuon = objPhien.GiaBanLuon
        require(_SoTienMuaLuon == objPhien.GiaBanLuon, "So tien mua luon khong hop le");
        
        //ktra co phai nguoi dat dau tien hay k
        if(objPhien.NguoiDatCuoi != address(0)){
            //Tra Tien Cho NguoiDatCuoi hien tai
            KhoTien.transfer(objPhien.NguoiDatCuoi, objPhien.GiaCuoiCung * (1 ether));
        }
        
        //Chuyen tien vao contract
        KhoTien.transferFrom(msg.sender, address(this), _SoTienMuaLuon * (1 ether));
        
        //Chuyen token cho nguoi mua 
        KhoNFT.safeTransferFrom(address(this) , msg.sender ,objPhien.tokenId);
        
        //Tra Tien Cho NguoiBan
        KhoTien.transfer(objPhien.NguoiBan, objPhien.GiaCuoiCung * (1 ether));
        
        objPhien.NguoiDatCuoi = msg.sender;
        objPhien.GiaCuoiCung = _SoTienMuaLuon;
        objPhien.HoatDong = false;
        
        //Dua ra thong bao
        emit MuaThanhCong(objPhien.tokenId);
    }
    
    function KetThucPhienDauGia(uint _MaPhien) external KiemTraPhienTonTai(_MaPhien) {
        PhienDauGia storage objPhien = DanhSachTatCaCacPhienDauGia[_MaPhien];
        
        if(msg.sender != NguoiTaoContract){
            //Kiem tra xem co phai NguoiBan/NguoiDatCuoi goi ham
            require(msg.sender == objPhien.NguoiBan || msg.sender == objPhien.NguoiDatCuoi, "Ban khong co quyen goi ham");
            _NguoiDungKetThucPhienDauGia(objPhien);
        } else {
            //Kiem tra admin goi ham la de ket thuc phien hay huy phien
            //TH huy thi return
            if(_AdminHuyPhienDauGia(objPhien) == true)
                return;
            //Th ket thuc thi tiep tuc chay
        }
        
        objPhien.HoatDong = false;
        
        if(objPhien.NguoiDatCuoi != address(0)){
            //Kiem tra xem token so huu boi NguoiDatCuoi chua
            if(KhoNFT.ownerOf(objPhien.tokenId) != objPhien.NguoiDatCuoi){
                //Chuyen token cho NguoiDatCuoi
                KhoNFT.safeTransferFrom(address(this) , objPhien.NguoiDatCuoi ,objPhien.tokenId);
            }
            
            //Tra Tien Cho NguoiBan
            KhoTien.transfer(objPhien.NguoiBan, objPhien.GiaCuoiCung * (1 ether));
        } else {
            //Neu phien ket thuc ma khong ai dau gia. Tra token cho NguoiBan
            KhoNFT.safeTransferFrom(address(this) , objPhien.NguoiBan ,objPhien.tokenId);
        }
        
        emit KetThucPhienDauGiaThanhCong(objPhien.MaPhien, objPhien.GiaCuoiCung == objPhien.GiaKhoiDiem ? 0 : objPhien.GiaCuoiCung);
    }
    
    function _NguoiDungKetThucPhienDauGia(PhienDauGia memory objPhien) view internal {
        require(objPhien.HoatDong == true, "Phien dau gia da ket thuc");
        require(objPhien.ThoiGianKetThuc <= block.timestamp, "Phien dau gia van dang dien ra");
    }
    
    function _AdminHuyPhienDauGia(PhienDauGia storage objPhien) internal KiemTraNguoiTaoContractGoiHam returns(bool)  {
        //Neu la admin
        //Kiem tra xem phien den thoi gian ket thuc chua
        if(block.timestamp < objPhien.ThoiGianKetThuc){
            //Neu chua
            //Kiem tra xem da co ai dau gia chua
            if(objPhien.NguoiDatCuoi != address(0)){
                //Neu co
                //Kiem tra xem token so huu boi NguoiDatCuoi chua
                require(KhoNFT.ownerOf(objPhien.tokenId) != objPhien.NguoiDatCuoi, "Nguoi mua da mua token nay roi");
                //Neu chua
                //Tra tien cho nguoi dat cuoi
                KhoTien.transfer(objPhien.NguoiDatCuoi, objPhien.GiaCuoiCung * (1 ether));
                //Tra token cho nguoi ban
                KhoNFT.safeTransferFrom(address(this) , objPhien.NguoiBan ,objPhien.tokenId);
                    
                objPhien.HoatDong = false;
                emit DaHuyPhienDauGia(objPhien.MaPhien);
                return true;
            }
        }
        return false;
    }
    
    // Mua Ban
    function TaoHopDongMuaBan(uint _tokenId, uint _TienHang) public {
        require(KhoNFT.ownerOf(_tokenId) != address(0), "Token id khong ton tai");
        //Kiem tra xem tokenId nay co dang dau gia tai phien khac hay khong?
        require(KiemTraTokenIdDaCoTrongPhienDauGiaHoatDong(_tokenId) == false, "Token nay dang duoc dau gia tai phien khac");
        //Kiem tra xem tokenId nay co dang ban tai HopDongMuaBan khac hay khong?
        require(KiemTraTokenIdDaCoTrongHopDongMuaBanHoatDong(_tokenId) == false, "Token nay dang duoc ban tai hop dong khac");
        
        //Kiem tra tien hang
        require(_TienHang > 0 , "Tien hang khong hop le");
        TongSoHopDong++;
        uint _MaHopDong = TongSoHopDong;
        DanhSachHopDongMuaBan[_MaHopDong] = HopDongMuaBan({
                                                            NguoiMua : address(0),
                                                            NguoiBan : msg.sender,
                                                            MaHopDong : _MaHopDong,
                                                            tokenId : _tokenId,
                                                            TienHang : _TienHang,
                                                            TienNguoiMuaGuiVao : 0,
                                                            TrangThaiHopDong : enTrangThaiHopDong.DangBan
                                                            });
                                                            
        //Chuyen token vao contract
        KhoNFT.safeTransferFrom(msg.sender, address(this), _tokenId);                                                    
        
        // thêm MaHopDong vào DanhSachHopDongCuaNguoiBan của NguoiBan 
        DanhSachHopDongCuaNguoiBan[msg.sender].push(_MaHopDong);
        
        emit TaoHopDongMuaBanThanhCong(_MaHopDong);
    }
    
    function MuaHang(uint _MaHopDong, uint _TienNguoiMuaGuiVao) public KiemTraHopDongTonTai(_MaHopDong){
        HopDongMuaBan storage objHopDong = DanhSachHopDongMuaBan[_MaHopDong];
        //Kiem tra trang thai hoat dong cua hop dong
        require(objHopDong.TrangThaiHopDong == enTrangThaiHopDong.DangBan, "Mat hang nay dang khong ban");
        // kiểm tra tiền trả 
        require(_TienNguoiMuaGuiVao == objHopDong.TienHang,"So tien gui vao khong hop le");
        // kiểm tra NguoiBan có phải là msg.sender
        require(msg.sender != objHopDong.NguoiBan, "Nguoi ban khong duoc mua");
        
        //Chuyen tien vao contract
        KhoTien.transferFrom(msg.sender, address(this), _TienNguoiMuaGuiVao * (1 ether));
        // chuyển quyền sở hữu token 
        KhoNFT.safeTransferFrom(address(this), msg.sender, objHopDong.tokenId);
        //Tra Tien Cho NguoiBan
        KhoTien.transfer(objHopDong.NguoiBan, objHopDong.TienHang * (1 ether));
        
        objHopDong.NguoiMua = msg.sender;
        objHopDong.TienNguoiMuaGuiVao = _TienNguoiMuaGuiVao;
        objHopDong.TrangThaiHopDong = enTrangThaiHopDong.DaBan;
        
        emit MuaHangThanhCong(objHopDong.tokenId, objHopDong.TienHang);
    }
    
    
    function HuyBanHang(uint _MaHopDong) public KiemTraHopDongTonTai(_MaHopDong) {
        HopDongMuaBan storage objHopDong = DanhSachHopDongMuaBan[_MaHopDong];
        // kiểm tra NguoiBan có phải là msg.sender
        require(msg.sender == objHopDong.NguoiBan || msg.sender == NguoiTaoContract, "Ban khong quyen huy ban");
        //Kiem tra trang thai hoat dong cua hop dong
        require(objHopDong.TrangThaiHopDong == enTrangThaiHopDong.DangBan, "Mat hang dang khong ban");
        
        // chuyển quyền sở hữu token cho NguoiBan
        KhoNFT.safeTransferFrom(address(this), objHopDong.NguoiBan, objHopDong.tokenId);
        
        objHopDong.TrangThaiHopDong = enTrangThaiHopDong.HuyBan;
        emit HuyBanHangThanhCong(objHopDong.MaHopDong);
    }
    
    function LayDanhSachMaHopDongSoHuu(address NguoiSoHuu) public view returns(uint[] memory) {
        return DanhSachHopDongCuaNguoiBan[NguoiSoHuu];
    }
    
    function LayDanhSachMaPhienDauGiaSoHuu(address NguoiSoHuu) public view returns(uint[] memory) {
        return DanhSachPhienDauGiaSoHuu[NguoiSoHuu];
    }
    
    function LayDanhSachMaPhienDauGiaThamGia(address NguoiThamGia) public view returns(uint[] memory) {
        return DanhSachPhienDauGiaThamGia[NguoiThamGia];
    }
    
}
