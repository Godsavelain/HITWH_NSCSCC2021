//const
`define	Valid 1'b1
`define Invalid 1'b0
`define Enable 1'b1
`define Disable 1'b0
`define Ready 1'b1
`define NotReady 1'b0
`define Success 1'b1
`define Fail 1'b0
`define Dirty 1'b1
`define NotDirty 1'b0
`define HitSuccess 1'b1
`define HitFail 1'b0
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define ChipEnable 1'b1//when rst is 1
`define ChipDisable 1'b0

`define DATA_CACHED 1'b1
`define DATA_UNCACHED 1'b0

`define ZeroWord 32'h00000000 

`define ICACHE_STATUS 1:0 
`define ICACHE_READ 2'b10
`define ICACHE_IDLE 2'b01

`define DCACHE_STATUS  `DCACHE_STATUS_W-1:0 
`define DCACHE_STATUS_W 5
`define DCACHE_IDLE 	5'b00001
`define DCACHE_CA_READ 	5'b00010
`define DCACHE_CA_WRITE 5'b00100
`define DCACHE_UC_READ  5'b01000//for uncache
`define DCACHE_UC_WRITE 5'b10000//for uncache

//Num
`define BlockNum 8
`define DBlockNum 16
`define SetNum 64
`define WaySize 256//32*8,the size of one way
`define ZeroWay `WaySize'h0

//Bus
`define InstAddrBus 31:0
`define InstBus 31:0
`define DataAddrBus 31:0
`define DataBus 31:0

`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32

`define OffsetBus 4:0
`define IndexBus 10:5
`define DIndexBus 11:6
`define TagBus 31:11
`define DTagBus 31:12
`define TagVBus 20:0
`define DTagVBus 19:0

`define WayBus 255:0
`define DWayBus 511:0
`define SetBus 63:0
`define DirtyBus 2*`SetNum-1:0





