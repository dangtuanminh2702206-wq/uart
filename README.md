# APB–UART + Nios V/c trên DE2-115

Project đầy đủ nằm trong [`quartus/de2_115_nios`](quartus/de2_115_nios).
Thư mục `rtl_nios_final` giữ 10 file đã bàn giao trước; riêng thư mục đó không đủ build hệ thống.

## Compile trong Quartus

1. Tải repository và giải nén vào đường dẫn ngắn, ví dụ `C:\FPGA\uart`.
2. Dùng Quartus Prime Lite **25.1std** có hỗ trợ **Cyclone IV E**.
3. Cấu hình license miễn phí **IP-NIOSVC** cho máy build trong Tools → License Setup.
   License cá nhân không được đưa vào repository.
4. Mở `quartus/de2_115_nios/de2_115_nios.qpf`.
   Top phải là `de2_115_nios_top`, device `EP4CE115F29C7`.
5. Chọn Processing → Start Compilation. File nạp sẽ là
   `output_files/de2_115_nios.sof`.

RTL sinh từ Platform Designer và firmware khởi tạo RAM đã có sẵn.
Không cần Add từng file, không cần tạo lại CPU hoặc build C để compile bản hiện tại.
Mở `nios_system.qsys` trong Platform Designer để xem CPU, RAM và kết nối.
Không thêm lại các file trong QIP bằng VERILOG_FILE vì QIP đã quản lý nguồn.

## Sửa firmware hoặc sinh lại hệ thống

Firmware C: `quartus/de2_115_nios/firmware/main.c`; startup và linker ở cùng thư mục.
Script mặc định dùng Quartus/RiscFree tại `C:\altera_lite\25.1std`.
Nếu cài nơi khác, truyền `-QuartusRoot` cho build script và chỉnh đường dẫn toolchain
trong `scripts/build_firmware.py`.

Trong thư mục project, chạy:

```powershell
.\build_all.cmd -LicenseFile 'C:\FPGA\niosvc_license.dat'
```

Script build firmware, kiểm tra binary/MIF, sinh Platform Designer, compile,
kiểm tra license/timing và đóng gói bản nạp.
Để chạy testbench RX/TX qua Avalon/APB, cài Python + Icarus Verilog rồi chạy:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_tests.ps1
```

## Thử trên board

- SW0 = 1, nhấn KEY0: PC dùng JTAG UART qua USB-Blaster. Firmware đưa byte qua
  UART TX → RX loopback nội bộ, hiển thị LCD và trả về PC.
- SW0 = 0, nhấn KEY0: dùng cổng DB9 với USB–RS232, **115200 / 8N1**, flow control None.
  Firmware nhận byte, hiển thị LCD và phát lại qua UART.
- Firmware đã nằm trong RAM khởi tạo từ SOF; không cần nạp ELF riêng.
- USB-Blaster dùng để nạp; không cắm tín hiệu TTL trực tiếp vào DB9 RS232.

## Mức xác minh

Project nguồn đã compile thành công trên Quartus Lite 25.1std với license Nios V/c:
0 lỗi, 0 critical warning, 84 warning; setup 50 MHz +6.227 ns, worst hold +0.111 ns.
Testbench UART/APB PASS 256 byte; firmware binary PASS ở hai chế độ.
Chưa xác nhận Nios/LCD/giao tiếp trên board thật. Compile 100% không thay thế thử phần cứng.

Nios RTL được sinh bởi Altera Platform Designer; sử dụng theo các điều khoản của
Altera và cần license IP phù hợp khi build.
