
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 c0 19 10 f0       	push   $0xf01019c0
f0100050:	e8 2e 0a 00 00       	call   f0100a83 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 0f 08 00 00       	call   f010088a <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 dc 19 10 f0       	push   $0xf01019dc
f0100087:	e8 f7 09 00 00       	call   f0100a83 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 76 14 00 00       	call   f0101527 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 7f 06 00 00       	call   f0100735 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 f7 19 10 f0       	push   $0xf01019f7
f01000c3:	e8 bb 09 00 00       	call   f0100a83 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 22 09 00 00       	call   f0100a03 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 12 1a 10 f0       	push   $0xf0101a12
f0100110:	e8 6e 09 00 00       	call   f0100a83 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 3e 09 00 00       	call   f0100a5d <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f0100126:	e8 58 09 00 00       	call   f0100a83 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 cb 08 00 00       	call   f0100a03 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 2a 1a 10 f0       	push   $0xf0101a2a
f0100152:	e8 2c 09 00 00       	call   f0100a83 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 fa 08 00 00       	call   f0100a5d <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 4e 1a 10 f0 	movl   $0xf0101a4e,(%esp)
f010016a:	e8 14 09 00 00       	call   f0100a83 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	89 c2                	mov    %eax,%edx
f010017c:	ec                   	in     (%dx),%al
	return data;
}
f010017d:	5d                   	pop    %ebp
f010017e:	c3                   	ret    

f010017f <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f010017f:	55                   	push   %ebp
f0100180:	89 e5                	mov    %esp,%ebp
f0100182:	89 c1                	mov    %eax,%ecx
f0100184:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100186:	89 ca                	mov    %ecx,%edx
f0100188:	ee                   	out    %al,(%dx)
}
f0100189:	5d                   	pop    %ebp
f010018a:	c3                   	ret    

f010018b <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010018b:	55                   	push   %ebp
f010018c:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f010018e:	b8 84 00 00 00       	mov    $0x84,%eax
f0100193:	e8 df ff ff ff       	call   f0100177 <inb>
	inb(0x84);
f0100198:	b8 84 00 00 00       	mov    $0x84,%eax
f010019d:	e8 d5 ff ff ff       	call   f0100177 <inb>
	inb(0x84);
f01001a2:	b8 84 00 00 00       	mov    $0x84,%eax
f01001a7:	e8 cb ff ff ff       	call   f0100177 <inb>
	inb(0x84);
f01001ac:	b8 84 00 00 00       	mov    $0x84,%eax
f01001b1:	e8 c1 ff ff ff       	call   f0100177 <inb>
}
f01001b6:	5d                   	pop    %ebp
f01001b7:	c3                   	ret    

f01001b8 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001b8:	55                   	push   %ebp
f01001b9:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bb:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001c0:	e8 b2 ff ff ff       	call   f0100177 <inb>
f01001c5:	a8 01                	test   $0x1,%al
f01001c7:	74 0f                	je     f01001d8 <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f01001c9:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001ce:	e8 a4 ff ff ff       	call   f0100177 <inb>
f01001d3:	0f b6 c0             	movzbl %al,%eax
f01001d6:	eb 05                	jmp    f01001dd <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001d8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001dd:	5d                   	pop    %ebp
f01001de:	c3                   	ret    

f01001df <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f01001df:	55                   	push   %ebp
f01001e0:	89 e5                	mov    %esp,%ebp
f01001e2:	56                   	push   %esi
f01001e3:	53                   	push   %ebx
f01001e4:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f01001e6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001eb:	eb 08                	jmp    f01001f5 <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001ed:	e8 99 ff ff ff       	call   f010018b <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01001f2:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001f5:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001fa:	e8 78 ff ff ff       	call   f0100177 <inb>
f01001ff:	a8 20                	test   $0x20,%al
f0100201:	75 08                	jne    f010020b <serial_putc+0x2c>
f0100203:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100209:	7e e2                	jle    f01001ed <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010020b:	89 f0                	mov    %esi,%eax
f010020d:	0f b6 d0             	movzbl %al,%edx
f0100210:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100215:	e8 65 ff ff ff       	call   f010017f <outb>
}
f010021a:	5b                   	pop    %ebx
f010021b:	5e                   	pop    %esi
f010021c:	5d                   	pop    %ebp
f010021d:	c3                   	ret    

f010021e <serial_init>:

static void
serial_init(void)
{
f010021e:	55                   	push   %ebp
f010021f:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f0100221:	ba 00 00 00 00       	mov    $0x0,%edx
f0100226:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f010022b:	e8 4f ff ff ff       	call   f010017f <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f0100230:	ba 80 00 00 00       	mov    $0x80,%edx
f0100235:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010023a:	e8 40 ff ff ff       	call   f010017f <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f010023f:	ba 0c 00 00 00       	mov    $0xc,%edx
f0100244:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100249:	e8 31 ff ff ff       	call   f010017f <outb>
	outb(COM1+COM_DLM, 0);
f010024e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100253:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100258:	e8 22 ff ff ff       	call   f010017f <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f010025d:	ba 03 00 00 00       	mov    $0x3,%edx
f0100262:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f0100267:	e8 13 ff ff ff       	call   f010017f <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010026c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100271:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100276:	e8 04 ff ff ff       	call   f010017f <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f010027b:	ba 01 00 00 00       	mov    $0x1,%edx
f0100280:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100285:	e8 f5 fe ff ff       	call   f010017f <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010028a:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f010028f:	e8 e3 fe ff ff       	call   f0100177 <inb>
f0100294:	3c ff                	cmp    $0xff,%al
f0100296:	0f 95 05 34 25 11 f0 	setne  0xf0112534
	(void) inb(COM1+COM_IIR);
f010029d:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01002a2:	e8 d0 fe ff ff       	call   f0100177 <inb>
	(void) inb(COM1+COM_RX);
f01002a7:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01002ac:	e8 c6 fe ff ff       	call   f0100177 <inb>

}
f01002b1:	5d                   	pop    %ebp
f01002b2:	c3                   	ret    

f01002b3 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f01002b3:	55                   	push   %ebp
f01002b4:	89 e5                	mov    %esp,%ebp
f01002b6:	56                   	push   %esi
f01002b7:	53                   	push   %ebx
f01002b8:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ba:	bb 00 00 00 00       	mov    $0x0,%ebx
f01002bf:	eb 08                	jmp    f01002c9 <lpt_putc+0x16>
		delay();
f01002c1:	e8 c5 fe ff ff       	call   f010018b <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002c6:	83 c3 01             	add    $0x1,%ebx
f01002c9:	b8 79 03 00 00       	mov    $0x379,%eax
f01002ce:	e8 a4 fe ff ff       	call   f0100177 <inb>
f01002d3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002d9:	7f 04                	jg     f01002df <lpt_putc+0x2c>
f01002db:	84 c0                	test   %al,%al
f01002dd:	79 e2                	jns    f01002c1 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f01002df:	89 f0                	mov    %esi,%eax
f01002e1:	0f b6 d0             	movzbl %al,%edx
f01002e4:	b8 78 03 00 00       	mov    $0x378,%eax
f01002e9:	e8 91 fe ff ff       	call   f010017f <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f01002ee:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002f3:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002f8:	e8 82 fe ff ff       	call   f010017f <outb>
	outb(0x378+2, 0x08);
f01002fd:	ba 08 00 00 00       	mov    $0x8,%edx
f0100302:	b8 7a 03 00 00       	mov    $0x37a,%eax
f0100307:	e8 73 fe ff ff       	call   f010017f <outb>
}
f010030c:	5b                   	pop    %ebx
f010030d:	5e                   	pop    %esi
f010030e:	5d                   	pop    %ebp
f010030f:	c3                   	ret    

f0100310 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f0100310:	55                   	push   %ebp
f0100311:	89 e5                	mov    %esp,%ebp
f0100313:	57                   	push   %edi
f0100314:	56                   	push   %esi
f0100315:	53                   	push   %ebx
f0100316:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100319:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100320:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100327:	5a a5 
	if (*cp != 0xA55A) {
f0100329:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100330:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100334:	74 13                	je     f0100349 <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100336:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010033d:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100340:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f0100347:	eb 18                	jmp    f0100361 <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100349:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100350:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100357:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010035a:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100361:	8b 35 30 25 11 f0    	mov    0xf0112530,%esi
f0100367:	ba 0e 00 00 00       	mov    $0xe,%edx
f010036c:	89 f0                	mov    %esi,%eax
f010036e:	e8 0c fe ff ff       	call   f010017f <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100373:	8d 7e 01             	lea    0x1(%esi),%edi
f0100376:	89 f8                	mov    %edi,%eax
f0100378:	e8 fa fd ff ff       	call   f0100177 <inb>
f010037d:	0f b6 d8             	movzbl %al,%ebx
f0100380:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100383:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100388:	89 f0                	mov    %esi,%eax
f010038a:	e8 f0 fd ff ff       	call   f010017f <outb>
	pos |= inb(addr_6845 + 1);
f010038f:	89 f8                	mov    %edi,%eax
f0100391:	e8 e1 fd ff ff       	call   f0100177 <inb>

	crt_buf = (uint16_t*) cp;
f0100396:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100399:	89 0d 2c 25 11 f0    	mov    %ecx,0xf011252c
	crt_pos = pos;
f010039f:	0f b6 c0             	movzbl %al,%eax
f01003a2:	09 c3                	or     %eax,%ebx
f01003a4:	66 89 1d 28 25 11 f0 	mov    %bx,0xf0112528
}
f01003ab:	83 c4 04             	add    $0x4,%esp
f01003ae:	5b                   	pop    %ebx
f01003af:	5e                   	pop    %esi
f01003b0:	5f                   	pop    %edi
f01003b1:	5d                   	pop    %ebp
f01003b2:	c3                   	ret    

f01003b3 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01003b3:	55                   	push   %ebp
f01003b4:	89 e5                	mov    %esp,%ebp
f01003b6:	53                   	push   %ebx
f01003b7:	83 ec 04             	sub    $0x4,%esp
f01003ba:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01003bc:	eb 2b                	jmp    f01003e9 <cons_intr+0x36>
		if (c == 0)
f01003be:	85 c0                	test   %eax,%eax
f01003c0:	74 27                	je     f01003e9 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01003c2:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01003c8:	8d 51 01             	lea    0x1(%ecx),%edx
f01003cb:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01003d1:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01003d7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003dd:	75 0a                	jne    f01003e9 <cons_intr+0x36>
			cons.wpos = 0;
f01003df:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01003e6:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003e9:	ff d3                	call   *%ebx
f01003eb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003ee:	75 ce                	jne    f01003be <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003f0:	83 c4 04             	add    $0x4,%esp
f01003f3:	5b                   	pop    %ebx
f01003f4:	5d                   	pop    %ebp
f01003f5:	c3                   	ret    

f01003f6 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003f6:	55                   	push   %ebp
f01003f7:	89 e5                	mov    %esp,%ebp
f01003f9:	53                   	push   %ebx
f01003fa:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003fd:	b8 64 00 00 00       	mov    $0x64,%eax
f0100402:	e8 70 fd ff ff       	call   f0100177 <inb>
	if ((stat & KBS_DIB) == 0)
f0100407:	a8 01                	test   $0x1,%al
f0100409:	0f 84 fe 00 00 00    	je     f010050d <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010040f:	a8 20                	test   $0x20,%al
f0100411:	0f 85 fd 00 00 00    	jne    f0100514 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f0100417:	b8 60 00 00 00       	mov    $0x60,%eax
f010041c:	e8 56 fd ff ff       	call   f0100177 <inb>

	if (data == 0xE0) {
f0100421:	3c e0                	cmp    $0xe0,%al
f0100423:	75 11                	jne    f0100436 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f0100425:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f010042c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100431:	e9 e7 00 00 00       	jmp    f010051d <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f0100436:	84 c0                	test   %al,%al
f0100438:	79 38                	jns    f0100472 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010043a:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100440:	89 cb                	mov    %ecx,%ebx
f0100442:	83 e3 40             	and    $0x40,%ebx
f0100445:	89 c2                	mov    %eax,%edx
f0100447:	83 e2 7f             	and    $0x7f,%edx
f010044a:	85 db                	test   %ebx,%ebx
f010044c:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f010044f:	0f b6 c0             	movzbl %al,%eax
f0100452:	0f b6 80 a0 1b 10 f0 	movzbl -0xfefe460(%eax),%eax
f0100459:	83 c8 40             	or     $0x40,%eax
f010045c:	0f b6 c0             	movzbl %al,%eax
f010045f:	f7 d0                	not    %eax
f0100461:	21 c8                	and    %ecx,%eax
f0100463:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100468:	b8 00 00 00 00       	mov    $0x0,%eax
f010046d:	e9 ab 00 00 00       	jmp    f010051d <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100472:	8b 15 00 23 11 f0    	mov    0xf0112300,%edx
f0100478:	f6 c2 40             	test   $0x40,%dl
f010047b:	74 0c                	je     f0100489 <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010047d:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100480:	83 e2 bf             	and    $0xffffffbf,%edx
f0100483:	89 15 00 23 11 f0    	mov    %edx,0xf0112300
	}

	shift |= shiftcode[data];
f0100489:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010048c:	0f b6 90 a0 1b 10 f0 	movzbl -0xfefe460(%eax),%edx
f0100493:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
f0100499:	0f b6 88 a0 1a 10 f0 	movzbl -0xfefe560(%eax),%ecx
f01004a0:	31 ca                	xor    %ecx,%edx
f01004a2:	89 15 00 23 11 f0    	mov    %edx,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f01004a8:	89 d1                	mov    %edx,%ecx
f01004aa:	83 e1 03             	and    $0x3,%ecx
f01004ad:	8b 0c 8d 80 1a 10 f0 	mov    -0xfefe580(,%ecx,4),%ecx
f01004b4:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f01004b8:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f01004bb:	f6 c2 08             	test   $0x8,%dl
f01004be:	74 1b                	je     f01004db <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004c5:	83 f9 19             	cmp    $0x19,%ecx
f01004c8:	77 05                	ja     f01004cf <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f01004ca:	83 eb 20             	sub    $0x20,%ebx
f01004cd:	eb 0c                	jmp    f01004db <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f01004cf:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01004d2:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004d5:	83 f8 19             	cmp    $0x19,%eax
f01004d8:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004db:	f7 d2                	not    %edx
f01004dd:	f6 c2 06             	test   $0x6,%dl
f01004e0:	75 39                	jne    f010051b <kbd_proc_data+0x125>
f01004e2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004e8:	75 31                	jne    f010051b <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f01004ea:	83 ec 0c             	sub    $0xc,%esp
f01004ed:	68 44 1a 10 f0       	push   $0xf0101a44
f01004f2:	e8 8c 05 00 00       	call   f0100a83 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004f7:	ba 03 00 00 00       	mov    $0x3,%edx
f01004fc:	b8 92 00 00 00       	mov    $0x92,%eax
f0100501:	e8 79 fc ff ff       	call   f010017f <outb>
f0100506:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f0100509:	89 d8                	mov    %ebx,%eax
f010050b:	eb 10                	jmp    f010051d <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f010050d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100512:	eb 09                	jmp    f010051d <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f0100514:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100519:	eb 02                	jmp    f010051d <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010051b:	89 d8                	mov    %ebx,%eax
}
f010051d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100520:	c9                   	leave  
f0100521:	c3                   	ret    

f0100522 <cga_putc>:



static void
cga_putc(int c)
{
f0100522:	55                   	push   %ebp
f0100523:	89 e5                	mov    %esp,%ebp
f0100525:	57                   	push   %edi
f0100526:	56                   	push   %esi
f0100527:	53                   	push   %ebx
f0100528:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010052b:	89 c1                	mov    %eax,%ecx
f010052d:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f0100533:	89 c2                	mov    %eax,%edx
f0100535:	80 ce 07             	or     $0x7,%dh
f0100538:	85 c9                	test   %ecx,%ecx
f010053a:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f010053d:	0f b6 d0             	movzbl %al,%edx
f0100540:	83 fa 09             	cmp    $0x9,%edx
f0100543:	74 72                	je     f01005b7 <cga_putc+0x95>
f0100545:	83 fa 09             	cmp    $0x9,%edx
f0100548:	7f 0a                	jg     f0100554 <cga_putc+0x32>
f010054a:	83 fa 08             	cmp    $0x8,%edx
f010054d:	74 14                	je     f0100563 <cga_putc+0x41>
f010054f:	e9 97 00 00 00       	jmp    f01005eb <cga_putc+0xc9>
f0100554:	83 fa 0a             	cmp    $0xa,%edx
f0100557:	74 38                	je     f0100591 <cga_putc+0x6f>
f0100559:	83 fa 0d             	cmp    $0xd,%edx
f010055c:	74 3b                	je     f0100599 <cga_putc+0x77>
f010055e:	e9 88 00 00 00       	jmp    f01005eb <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100563:	0f b7 15 28 25 11 f0 	movzwl 0xf0112528,%edx
f010056a:	66 85 d2             	test   %dx,%dx
f010056d:	0f 84 e4 00 00 00    	je     f0100657 <cga_putc+0x135>
			crt_pos--;
f0100573:	83 ea 01             	sub    $0x1,%edx
f0100576:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010057d:	0f b7 d2             	movzwl %dx,%edx
f0100580:	b0 00                	mov    $0x0,%al
f0100582:	83 c8 20             	or     $0x20,%eax
f0100585:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f010058b:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f010058f:	eb 78                	jmp    f0100609 <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100591:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f0100598:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100599:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01005a0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01005a6:	c1 e8 16             	shr    $0x16,%eax
f01005a9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01005ac:	c1 e0 04             	shl    $0x4,%eax
f01005af:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
		break;
f01005b5:	eb 52                	jmp    f0100609 <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f01005b7:	b8 20 00 00 00       	mov    $0x20,%eax
f01005bc:	e8 da 00 00 00       	call   f010069b <cons_putc>
		cons_putc(' ');
f01005c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01005c6:	e8 d0 00 00 00       	call   f010069b <cons_putc>
		cons_putc(' ');
f01005cb:	b8 20 00 00 00       	mov    $0x20,%eax
f01005d0:	e8 c6 00 00 00       	call   f010069b <cons_putc>
		cons_putc(' ');
f01005d5:	b8 20 00 00 00       	mov    $0x20,%eax
f01005da:	e8 bc 00 00 00       	call   f010069b <cons_putc>
		cons_putc(' ');
f01005df:	b8 20 00 00 00       	mov    $0x20,%eax
f01005e4:	e8 b2 00 00 00       	call   f010069b <cons_putc>
		break;
f01005e9:	eb 1e                	jmp    f0100609 <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005eb:	0f b7 15 28 25 11 f0 	movzwl 0xf0112528,%edx
f01005f2:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005f5:	66 89 0d 28 25 11 f0 	mov    %cx,0xf0112528
f01005fc:	0f b7 d2             	movzwl %dx,%edx
f01005ff:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f0100605:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100609:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100610:	cf 07 
f0100612:	76 43                	jbe    f0100657 <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100614:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100619:	83 ec 04             	sub    $0x4,%esp
f010061c:	68 00 0f 00 00       	push   $0xf00
f0100621:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100627:	52                   	push   %edx
f0100628:	50                   	push   %eax
f0100629:	e8 47 0f 00 00       	call   f0101575 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010062e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100634:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010063a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100640:	83 c4 10             	add    $0x10,%esp
f0100643:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100648:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010064b:	39 d0                	cmp    %edx,%eax
f010064d:	75 f4                	jne    f0100643 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010064f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100656:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100657:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f010065d:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100662:	89 f8                	mov    %edi,%eax
f0100664:	e8 16 fb ff ff       	call   f010017f <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100669:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f0100670:	8d 77 01             	lea    0x1(%edi),%esi
f0100673:	0f b6 d7             	movzbl %bh,%edx
f0100676:	89 f0                	mov    %esi,%eax
f0100678:	e8 02 fb ff ff       	call   f010017f <outb>
	outb(addr_6845, 15);
f010067d:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100682:	89 f8                	mov    %edi,%eax
f0100684:	e8 f6 fa ff ff       	call   f010017f <outb>
	outb(addr_6845 + 1, crt_pos);
f0100689:	0f b6 d3             	movzbl %bl,%edx
f010068c:	89 f0                	mov    %esi,%eax
f010068e:	e8 ec fa ff ff       	call   f010017f <outb>
}
f0100693:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100696:	5b                   	pop    %ebx
f0100697:	5e                   	pop    %esi
f0100698:	5f                   	pop    %edi
f0100699:	5d                   	pop    %ebp
f010069a:	c3                   	ret    

f010069b <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010069b:	55                   	push   %ebp
f010069c:	89 e5                	mov    %esp,%ebp
f010069e:	53                   	push   %ebx
f010069f:	83 ec 04             	sub    $0x4,%esp
f01006a2:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f01006a4:	e8 36 fb ff ff       	call   f01001df <serial_putc>
	lpt_putc(c);
f01006a9:	89 d8                	mov    %ebx,%eax
f01006ab:	e8 03 fc ff ff       	call   f01002b3 <lpt_putc>
	cga_putc(c);
f01006b0:	89 d8                	mov    %ebx,%eax
f01006b2:	e8 6b fe ff ff       	call   f0100522 <cga_putc>
}
f01006b7:	83 c4 04             	add    $0x4,%esp
f01006ba:	5b                   	pop    %ebx
f01006bb:	5d                   	pop    %ebp
f01006bc:	c3                   	ret    

f01006bd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01006bd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01006c4:	74 11                	je     f01006d7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01006cc:	b8 b8 01 10 f0       	mov    $0xf01001b8,%eax
f01006d1:	e8 dd fc ff ff       	call   f01003b3 <cons_intr>
}
f01006d6:	c9                   	leave  
f01006d7:	f3 c3                	repz ret 

f01006d9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01006d9:	55                   	push   %ebp
f01006da:	89 e5                	mov    %esp,%ebp
f01006dc:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006df:	b8 f6 03 10 f0       	mov    $0xf01003f6,%eax
f01006e4:	e8 ca fc ff ff       	call   f01003b3 <cons_intr>
}
f01006e9:	c9                   	leave  
f01006ea:	c3                   	ret    

f01006eb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01006eb:	55                   	push   %ebp
f01006ec:	89 e5                	mov    %esp,%ebp
f01006ee:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01006f1:	e8 c7 ff ff ff       	call   f01006bd <serial_intr>
	kbd_intr();
f01006f6:	e8 de ff ff ff       	call   f01006d9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006fb:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100700:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100706:	74 26                	je     f010072e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100708:	8d 50 01             	lea    0x1(%eax),%edx
f010070b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100711:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100718:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010071a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100720:	75 11                	jne    f0100733 <cons_getc+0x48>
			cons.rpos = 0;
f0100722:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100729:	00 00 00 
f010072c:	eb 05                	jmp    f0100733 <cons_getc+0x48>
		return c;
	}
	return 0;
f010072e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100733:	c9                   	leave  
f0100734:	c3                   	ret    

f0100735 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100735:	55                   	push   %ebp
f0100736:	89 e5                	mov    %esp,%ebp
f0100738:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f010073b:	e8 d0 fb ff ff       	call   f0100310 <cga_init>
	kbd_init();
	serial_init();
f0100740:	e8 d9 fa ff ff       	call   f010021e <serial_init>

	if (!serial_exists)
f0100745:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f010074c:	75 10                	jne    f010075e <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f010074e:	83 ec 0c             	sub    $0xc,%esp
f0100751:	68 50 1a 10 f0       	push   $0xf0101a50
f0100756:	e8 28 03 00 00       	call   f0100a83 <cprintf>
f010075b:	83 c4 10             	add    $0x10,%esp
}
f010075e:	c9                   	leave  
f010075f:	c3                   	ret    

f0100760 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100760:	55                   	push   %ebp
f0100761:	89 e5                	mov    %esp,%ebp
f0100763:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100766:	8b 45 08             	mov    0x8(%ebp),%eax
f0100769:	e8 2d ff ff ff       	call   f010069b <cons_putc>
}
f010076e:	c9                   	leave  
f010076f:	c3                   	ret    

f0100770 <getchar>:

int
getchar(void)
{
f0100770:	55                   	push   %ebp
f0100771:	89 e5                	mov    %esp,%ebp
f0100773:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100776:	e8 70 ff ff ff       	call   f01006eb <cons_getc>
f010077b:	85 c0                	test   %eax,%eax
f010077d:	74 f7                	je     f0100776 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010077f:	c9                   	leave  
f0100780:	c3                   	ret    

f0100781 <iscons>:

int
iscons(int fdnum)
{
f0100781:	55                   	push   %ebp
f0100782:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100784:	b8 01 00 00 00       	mov    $0x1,%eax
f0100789:	5d                   	pop    %ebp
f010078a:	c3                   	ret    

f010078b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010078b:	55                   	push   %ebp
f010078c:	89 e5                	mov    %esp,%ebp
f010078e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100791:	68 a0 1c 10 f0       	push   $0xf0101ca0
f0100796:	68 be 1c 10 f0       	push   $0xf0101cbe
f010079b:	68 c3 1c 10 f0       	push   $0xf0101cc3
f01007a0:	e8 de 02 00 00       	call   f0100a83 <cprintf>
f01007a5:	83 c4 0c             	add    $0xc,%esp
f01007a8:	68 60 1d 10 f0       	push   $0xf0101d60
f01007ad:	68 cc 1c 10 f0       	push   $0xf0101ccc
f01007b2:	68 c3 1c 10 f0       	push   $0xf0101cc3
f01007b7:	e8 c7 02 00 00       	call   f0100a83 <cprintf>
f01007bc:	83 c4 0c             	add    $0xc,%esp
f01007bf:	68 d5 1c 10 f0       	push   $0xf0101cd5
f01007c4:	68 e9 1c 10 f0       	push   $0xf0101ce9
f01007c9:	68 c3 1c 10 f0       	push   $0xf0101cc3
f01007ce:	e8 b0 02 00 00       	call   f0100a83 <cprintf>
	return 0;
}
f01007d3:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d8:	c9                   	leave  
f01007d9:	c3                   	ret    

f01007da <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007da:	55                   	push   %ebp
f01007db:	89 e5                	mov    %esp,%ebp
f01007dd:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007e0:	68 f3 1c 10 f0       	push   $0xf0101cf3
f01007e5:	e8 99 02 00 00       	call   f0100a83 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ea:	83 c4 08             	add    $0x8,%esp
f01007ed:	68 0c 00 10 00       	push   $0x10000c
f01007f2:	68 88 1d 10 f0       	push   $0xf0101d88
f01007f7:	e8 87 02 00 00       	call   f0100a83 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007fc:	83 c4 0c             	add    $0xc,%esp
f01007ff:	68 0c 00 10 00       	push   $0x10000c
f0100804:	68 0c 00 10 f0       	push   $0xf010000c
f0100809:	68 b0 1d 10 f0       	push   $0xf0101db0
f010080e:	e8 70 02 00 00       	call   f0100a83 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100813:	83 c4 0c             	add    $0xc,%esp
f0100816:	68 b1 19 10 00       	push   $0x1019b1
f010081b:	68 b1 19 10 f0       	push   $0xf01019b1
f0100820:	68 d4 1d 10 f0       	push   $0xf0101dd4
f0100825:	e8 59 02 00 00       	call   f0100a83 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010082a:	83 c4 0c             	add    $0xc,%esp
f010082d:	68 00 23 11 00       	push   $0x112300
f0100832:	68 00 23 11 f0       	push   $0xf0112300
f0100837:	68 f8 1d 10 f0       	push   $0xf0101df8
f010083c:	e8 42 02 00 00       	call   f0100a83 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100841:	83 c4 0c             	add    $0xc,%esp
f0100844:	68 44 29 11 00       	push   $0x112944
f0100849:	68 44 29 11 f0       	push   $0xf0112944
f010084e:	68 1c 1e 10 f0       	push   $0xf0101e1c
f0100853:	e8 2b 02 00 00       	call   f0100a83 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100858:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010085d:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100862:	83 c4 08             	add    $0x8,%esp
f0100865:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010086a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100870:	85 c0                	test   %eax,%eax
f0100872:	0f 48 c2             	cmovs  %edx,%eax
f0100875:	c1 f8 0a             	sar    $0xa,%eax
f0100878:	50                   	push   %eax
f0100879:	68 40 1e 10 f0       	push   $0xf0101e40
f010087e:	e8 00 02 00 00       	call   f0100a83 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100883:	b8 00 00 00 00       	mov    $0x0,%eax
f0100888:	c9                   	leave  
f0100889:	c3                   	ret    

f010088a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010088a:	55                   	push   %ebp
f010088b:	89 e5                	mov    %esp,%ebp
f010088d:	57                   	push   %edi
f010088e:	56                   	push   %esi
f010088f:	53                   	push   %ebx
f0100890:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100893:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100895:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100898:	eb 4a                	jmp    f01008e4 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f010089a:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f010089d:	ff 73 18             	pushl  0x18(%ebx)
f01008a0:	ff 73 14             	pushl  0x14(%ebx)
f01008a3:	ff 73 10             	pushl  0x10(%ebx)
f01008a6:	ff 73 0c             	pushl  0xc(%ebx)
f01008a9:	ff 73 08             	pushl  0x8(%ebx)
f01008ac:	56                   	push   %esi
f01008ad:	53                   	push   %ebx
f01008ae:	68 6c 1e 10 f0       	push   $0xf0101e6c
f01008b3:	e8 cb 01 00 00       	call   f0100a83 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f01008b8:	83 c4 18             	add    $0x18,%esp
f01008bb:	57                   	push   %edi
f01008bc:	56                   	push   %esi
f01008bd:	e8 cb 02 00 00       	call   f0100b8d <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f01008c2:	83 c4 08             	add    $0x8,%esp
f01008c5:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01008c8:	56                   	push   %esi
f01008c9:	ff 75 d8             	pushl  -0x28(%ebp)
f01008cc:	ff 75 dc             	pushl  -0x24(%ebp)
f01008cf:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008d2:	ff 75 d0             	pushl  -0x30(%ebp)
f01008d5:	68 0c 1d 10 f0       	push   $0xf0101d0c
f01008da:	e8 a4 01 00 00       	call   f0100a83 <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f01008df:	8b 1b                	mov    (%ebx),%ebx
f01008e1:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f01008e4:	85 db                	test   %ebx,%ebx
f01008e6:	75 b2                	jne    f010089a <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f01008e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008f0:	5b                   	pop    %ebx
f01008f1:	5e                   	pop    %esi
f01008f2:	5f                   	pop    %edi
f01008f3:	5d                   	pop    %ebp
f01008f4:	c3                   	ret    

f01008f5 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f01008f5:	55                   	push   %ebp
f01008f6:	89 e5                	mov    %esp,%ebp
f01008f8:	57                   	push   %edi
f01008f9:	56                   	push   %esi
f01008fa:	53                   	push   %ebx
f01008fb:	83 ec 5c             	sub    $0x5c,%esp
f01008fe:	89 c3                	mov    %eax,%ebx
f0100900:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100903:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010090a:	be 00 00 00 00       	mov    $0x0,%esi
f010090f:	eb 0a                	jmp    f010091b <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100911:	c6 03 00             	movb   $0x0,(%ebx)
f0100914:	89 f7                	mov    %esi,%edi
f0100916:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100919:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010091b:	0f b6 03             	movzbl (%ebx),%eax
f010091e:	84 c0                	test   %al,%al
f0100920:	74 6d                	je     f010098f <runcmd+0x9a>
f0100922:	83 ec 08             	sub    $0x8,%esp
f0100925:	0f be c0             	movsbl %al,%eax
f0100928:	50                   	push   %eax
f0100929:	68 23 1d 10 f0       	push   $0xf0101d23
f010092e:	e8 b7 0b 00 00       	call   f01014ea <strchr>
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	85 c0                	test   %eax,%eax
f0100938:	75 d7                	jne    f0100911 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f010093a:	0f b6 03             	movzbl (%ebx),%eax
f010093d:	84 c0                	test   %al,%al
f010093f:	74 4e                	je     f010098f <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100941:	83 fe 0f             	cmp    $0xf,%esi
f0100944:	75 1c                	jne    f0100962 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100946:	83 ec 08             	sub    $0x8,%esp
f0100949:	6a 10                	push   $0x10
f010094b:	68 28 1d 10 f0       	push   $0xf0101d28
f0100950:	e8 2e 01 00 00       	call   f0100a83 <cprintf>
			return 0;
f0100955:	83 c4 10             	add    $0x10,%esp
f0100958:	b8 00 00 00 00       	mov    $0x0,%eax
f010095d:	e9 99 00 00 00       	jmp    f01009fb <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100962:	8d 7e 01             	lea    0x1(%esi),%edi
f0100965:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100969:	eb 0a                	jmp    f0100975 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010096b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010096e:	0f b6 03             	movzbl (%ebx),%eax
f0100971:	84 c0                	test   %al,%al
f0100973:	74 a4                	je     f0100919 <runcmd+0x24>
f0100975:	83 ec 08             	sub    $0x8,%esp
f0100978:	0f be c0             	movsbl %al,%eax
f010097b:	50                   	push   %eax
f010097c:	68 23 1d 10 f0       	push   $0xf0101d23
f0100981:	e8 64 0b 00 00       	call   f01014ea <strchr>
f0100986:	83 c4 10             	add    $0x10,%esp
f0100989:	85 c0                	test   %eax,%eax
f010098b:	74 de                	je     f010096b <runcmd+0x76>
f010098d:	eb 8a                	jmp    f0100919 <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f010098f:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100996:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f0100997:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f010099c:	85 f6                	test   %esi,%esi
f010099e:	74 5b                	je     f01009fb <runcmd+0x106>
f01009a0:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a5:	83 ec 08             	sub    $0x8,%esp
f01009a8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009ab:	ff 34 85 00 1f 10 f0 	pushl  -0xfefe100(,%eax,4)
f01009b2:	ff 75 a8             	pushl  -0x58(%ebp)
f01009b5:	e8 d2 0a 00 00       	call   f010148c <strcmp>
f01009ba:	83 c4 10             	add    $0x10,%esp
f01009bd:	85 c0                	test   %eax,%eax
f01009bf:	75 1a                	jne    f01009db <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f01009c1:	83 ec 04             	sub    $0x4,%esp
f01009c4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009c7:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009ca:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009cd:	52                   	push   %edx
f01009ce:	56                   	push   %esi
f01009cf:	ff 14 85 08 1f 10 f0 	call   *-0xfefe0f8(,%eax,4)
f01009d6:	83 c4 10             	add    $0x10,%esp
f01009d9:	eb 20                	jmp    f01009fb <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009db:	83 c3 01             	add    $0x1,%ebx
f01009de:	83 fb 03             	cmp    $0x3,%ebx
f01009e1:	75 c2                	jne    f01009a5 <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009e3:	83 ec 08             	sub    $0x8,%esp
f01009e6:	ff 75 a8             	pushl  -0x58(%ebp)
f01009e9:	68 45 1d 10 f0       	push   $0xf0101d45
f01009ee:	e8 90 00 00 00       	call   f0100a83 <cprintf>
	return 0;
f01009f3:	83 c4 10             	add    $0x10,%esp
f01009f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009fb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009fe:	5b                   	pop    %ebx
f01009ff:	5e                   	pop    %esi
f0100a00:	5f                   	pop    %edi
f0100a01:	5d                   	pop    %ebp
f0100a02:	c3                   	ret    

f0100a03 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100a03:	55                   	push   %ebp
f0100a04:	89 e5                	mov    %esp,%ebp
f0100a06:	53                   	push   %ebx
f0100a07:	83 ec 10             	sub    $0x10,%esp
f0100a0a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a0d:	68 a0 1e 10 f0       	push   $0xf0101ea0
f0100a12:	e8 6c 00 00 00       	call   f0100a83 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a17:	c7 04 24 c4 1e 10 f0 	movl   $0xf0101ec4,(%esp)
f0100a1e:	e8 60 00 00 00       	call   f0100a83 <cprintf>
f0100a23:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100a26:	83 ec 0c             	sub    $0xc,%esp
f0100a29:	68 5b 1d 10 f0       	push   $0xf0101d5b
f0100a2e:	e8 9d 08 00 00       	call   f01012d0 <readline>
		if (buf != NULL)
f0100a33:	83 c4 10             	add    $0x10,%esp
f0100a36:	85 c0                	test   %eax,%eax
f0100a38:	74 ec                	je     f0100a26 <monitor+0x23>
			if (runcmd(buf, tf) < 0)
f0100a3a:	89 da                	mov    %ebx,%edx
f0100a3c:	e8 b4 fe ff ff       	call   f01008f5 <runcmd>
f0100a41:	85 c0                	test   %eax,%eax
f0100a43:	79 e1                	jns    f0100a26 <monitor+0x23>
				break;
	}
}
f0100a45:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a48:	c9                   	leave  
f0100a49:	c3                   	ret    

f0100a4a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a4a:	55                   	push   %ebp
f0100a4b:	89 e5                	mov    %esp,%ebp
f0100a4d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100a50:	ff 75 08             	pushl  0x8(%ebp)
f0100a53:	e8 08 fd ff ff       	call   f0100760 <cputchar>
	*cnt++;
}
f0100a58:	83 c4 10             	add    $0x10,%esp
f0100a5b:	c9                   	leave  
f0100a5c:	c3                   	ret    

f0100a5d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a5d:	55                   	push   %ebp
f0100a5e:	89 e5                	mov    %esp,%ebp
f0100a60:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100a63:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a6a:	ff 75 0c             	pushl  0xc(%ebp)
f0100a6d:	ff 75 08             	pushl  0x8(%ebp)
f0100a70:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a73:	50                   	push   %eax
f0100a74:	68 4a 0a 10 f0       	push   $0xf0100a4a
f0100a79:	e8 82 04 00 00       	call   f0100f00 <vprintfmt>
	return cnt;
}
f0100a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a81:	c9                   	leave  
f0100a82:	c3                   	ret    

f0100a83 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a83:	55                   	push   %ebp
f0100a84:	89 e5                	mov    %esp,%ebp
f0100a86:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a89:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a8c:	50                   	push   %eax
f0100a8d:	ff 75 08             	pushl  0x8(%ebp)
f0100a90:	e8 c8 ff ff ff       	call   f0100a5d <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a95:	c9                   	leave  
f0100a96:	c3                   	ret    

f0100a97 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a97:	55                   	push   %ebp
f0100a98:	89 e5                	mov    %esp,%ebp
f0100a9a:	57                   	push   %edi
f0100a9b:	56                   	push   %esi
f0100a9c:	53                   	push   %ebx
f0100a9d:	83 ec 14             	sub    $0x14,%esp
f0100aa0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100aa3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100aa6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100aa9:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100aac:	8b 1a                	mov    (%edx),%ebx
f0100aae:	8b 01                	mov    (%ecx),%eax
f0100ab0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ab3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100aba:	eb 7f                	jmp    f0100b3b <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100abc:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100abf:	01 d8                	add    %ebx,%eax
f0100ac1:	89 c6                	mov    %eax,%esi
f0100ac3:	c1 ee 1f             	shr    $0x1f,%esi
f0100ac6:	01 c6                	add    %eax,%esi
f0100ac8:	d1 fe                	sar    %esi
f0100aca:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100acd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ad0:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100ad3:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ad5:	eb 03                	jmp    f0100ada <stab_binsearch+0x43>
			m--;
f0100ad7:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ada:	39 c3                	cmp    %eax,%ebx
f0100adc:	7f 0d                	jg     f0100aeb <stab_binsearch+0x54>
f0100ade:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100ae2:	83 ea 0c             	sub    $0xc,%edx
f0100ae5:	39 f9                	cmp    %edi,%ecx
f0100ae7:	75 ee                	jne    f0100ad7 <stab_binsearch+0x40>
f0100ae9:	eb 05                	jmp    f0100af0 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100aeb:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100aee:	eb 4b                	jmp    f0100b3b <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100af0:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100af3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100af6:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100afa:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100afd:	76 11                	jbe    f0100b10 <stab_binsearch+0x79>
			*region_left = m;
f0100aff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100b02:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100b04:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b07:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b0e:	eb 2b                	jmp    f0100b3b <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b10:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100b13:	73 14                	jae    f0100b29 <stab_binsearch+0x92>
			*region_right = m - 1;
f0100b15:	83 e8 01             	sub    $0x1,%eax
f0100b18:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b1b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b1e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b20:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b27:	eb 12                	jmp    f0100b3b <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b29:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b2c:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b2e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b32:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b34:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b3b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b3e:	0f 8e 78 ff ff ff    	jle    f0100abc <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b44:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b48:	75 0f                	jne    f0100b59 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100b4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b4d:	8b 00                	mov    (%eax),%eax
f0100b4f:	83 e8 01             	sub    $0x1,%eax
f0100b52:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b55:	89 06                	mov    %eax,(%esi)
f0100b57:	eb 2c                	jmp    f0100b85 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b59:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b5c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b5e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b61:	8b 0e                	mov    (%esi),%ecx
f0100b63:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b66:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b69:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b6c:	eb 03                	jmp    f0100b71 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b6e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b71:	39 c8                	cmp    %ecx,%eax
f0100b73:	7e 0b                	jle    f0100b80 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100b75:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100b79:	83 ea 0c             	sub    $0xc,%edx
f0100b7c:	39 df                	cmp    %ebx,%edi
f0100b7e:	75 ee                	jne    f0100b6e <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b80:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b83:	89 06                	mov    %eax,(%esi)
	}
}
f0100b85:	83 c4 14             	add    $0x14,%esp
f0100b88:	5b                   	pop    %ebx
f0100b89:	5e                   	pop    %esi
f0100b8a:	5f                   	pop    %edi
f0100b8b:	5d                   	pop    %ebp
f0100b8c:	c3                   	ret    

f0100b8d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b8d:	55                   	push   %ebp
f0100b8e:	89 e5                	mov    %esp,%ebp
f0100b90:	57                   	push   %edi
f0100b91:	56                   	push   %esi
f0100b92:	53                   	push   %ebx
f0100b93:	83 ec 3c             	sub    $0x3c,%esp
f0100b96:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b99:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b9c:	c7 03 24 1f 10 f0    	movl   $0xf0101f24,(%ebx)
	info->eip_line = 0;
f0100ba2:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ba9:	c7 43 08 24 1f 10 f0 	movl   $0xf0101f24,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100bb0:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100bb7:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100bba:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bc1:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bc7:	76 11                	jbe    f0100bda <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bc9:	b8 2c 76 10 f0       	mov    $0xf010762c,%eax
f0100bce:	3d 31 5c 10 f0       	cmp    $0xf0105c31,%eax
f0100bd3:	77 19                	ja     f0100bee <debuginfo_eip+0x61>
f0100bd5:	e9 af 01 00 00       	jmp    f0100d89 <debuginfo_eip+0x1fc>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100bda:	83 ec 04             	sub    $0x4,%esp
f0100bdd:	68 2e 1f 10 f0       	push   $0xf0101f2e
f0100be2:	6a 7f                	push   $0x7f
f0100be4:	68 3b 1f 10 f0       	push   $0xf0101f3b
f0100be9:	e8 f8 f4 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bee:	80 3d 2b 76 10 f0 00 	cmpb   $0x0,0xf010762b
f0100bf5:	0f 85 95 01 00 00    	jne    f0100d90 <debuginfo_eip+0x203>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bfb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c02:	b8 30 5c 10 f0       	mov    $0xf0105c30,%eax
f0100c07:	2d 5c 21 10 f0       	sub    $0xf010215c,%eax
f0100c0c:	c1 f8 02             	sar    $0x2,%eax
f0100c0f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c15:	83 e8 01             	sub    $0x1,%eax
f0100c18:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c1b:	83 ec 08             	sub    $0x8,%esp
f0100c1e:	56                   	push   %esi
f0100c1f:	6a 64                	push   $0x64
f0100c21:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c24:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c27:	b8 5c 21 10 f0       	mov    $0xf010215c,%eax
f0100c2c:	e8 66 fe ff ff       	call   f0100a97 <stab_binsearch>
	if (lfile == 0)
f0100c31:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c34:	83 c4 10             	add    $0x10,%esp
f0100c37:	85 c0                	test   %eax,%eax
f0100c39:	0f 84 58 01 00 00    	je     f0100d97 <debuginfo_eip+0x20a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c3f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c42:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c45:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c48:	83 ec 08             	sub    $0x8,%esp
f0100c4b:	56                   	push   %esi
f0100c4c:	6a 24                	push   $0x24
f0100c4e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c51:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c54:	b8 5c 21 10 f0       	mov    $0xf010215c,%eax
f0100c59:	e8 39 fe ff ff       	call   f0100a97 <stab_binsearch>

	if (lfun <= rfun) {
f0100c5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c61:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c64:	83 c4 10             	add    $0x10,%esp
f0100c67:	39 d0                	cmp    %edx,%eax
f0100c69:	7f 40                	jg     f0100cab <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c6b:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100c6e:	c1 e1 02             	shl    $0x2,%ecx
f0100c71:	8d b9 5c 21 10 f0    	lea    -0xfefdea4(%ecx),%edi
f0100c77:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c7a:	8b b9 5c 21 10 f0    	mov    -0xfefdea4(%ecx),%edi
f0100c80:	b9 2c 76 10 f0       	mov    $0xf010762c,%ecx
f0100c85:	81 e9 31 5c 10 f0    	sub    $0xf0105c31,%ecx
f0100c8b:	39 cf                	cmp    %ecx,%edi
f0100c8d:	73 09                	jae    f0100c98 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c8f:	81 c7 31 5c 10 f0    	add    $0xf0105c31,%edi
f0100c95:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c98:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c9b:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c9e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ca1:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ca3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ca6:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ca9:	eb 0f                	jmp    f0100cba <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100cab:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100cae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cb1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100cb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cb7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100cba:	83 ec 08             	sub    $0x8,%esp
f0100cbd:	6a 3a                	push   $0x3a
f0100cbf:	ff 73 08             	pushl  0x8(%ebx)
f0100cc2:	e8 44 08 00 00       	call   f010150b <strfind>
f0100cc7:	2b 43 08             	sub    0x8(%ebx),%eax
f0100cca:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100ccd:	83 c4 08             	add    $0x8,%esp
f0100cd0:	56                   	push   %esi
f0100cd1:	6a 44                	push   $0x44
f0100cd3:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100cd6:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100cd9:	b8 5c 21 10 f0       	mov    $0xf010215c,%eax
f0100cde:	e8 b4 fd ff ff       	call   f0100a97 <stab_binsearch>
	if (lline <= rline) {
f0100ce3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ce6:	83 c4 10             	add    $0x10,%esp
f0100ce9:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100cec:	7f 0e                	jg     f0100cfc <debuginfo_eip+0x16f>
		info->eip_line = stabs[lline].n_desc;
f0100cee:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100cf1:	0f b7 14 95 62 21 10 	movzwl -0xfefde9e(,%edx,4),%edx
f0100cf8:	f0 
f0100cf9:	89 53 04             	mov    %edx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cfc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100cff:	89 c2                	mov    %eax,%edx
f0100d01:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100d04:	8d 04 85 5c 21 10 f0 	lea    -0xfefdea4(,%eax,4),%eax
f0100d0b:	eb 06                	jmp    f0100d13 <debuginfo_eip+0x186>
f0100d0d:	83 ea 01             	sub    $0x1,%edx
f0100d10:	83 e8 0c             	sub    $0xc,%eax
f0100d13:	39 d7                	cmp    %edx,%edi
f0100d15:	7f 34                	jg     f0100d4b <debuginfo_eip+0x1be>
	       && stabs[lline].n_type != N_SOL
f0100d17:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100d1b:	80 f9 84             	cmp    $0x84,%cl
f0100d1e:	74 0b                	je     f0100d2b <debuginfo_eip+0x19e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d20:	80 f9 64             	cmp    $0x64,%cl
f0100d23:	75 e8                	jne    f0100d0d <debuginfo_eip+0x180>
f0100d25:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100d29:	74 e2                	je     f0100d0d <debuginfo_eip+0x180>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d2b:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100d2e:	8b 14 85 5c 21 10 f0 	mov    -0xfefdea4(,%eax,4),%edx
f0100d35:	b8 2c 76 10 f0       	mov    $0xf010762c,%eax
f0100d3a:	2d 31 5c 10 f0       	sub    $0xf0105c31,%eax
f0100d3f:	39 c2                	cmp    %eax,%edx
f0100d41:	73 08                	jae    f0100d4b <debuginfo_eip+0x1be>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d43:	81 c2 31 5c 10 f0    	add    $0xf0105c31,%edx
f0100d49:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d4b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d4e:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d51:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d56:	39 f2                	cmp    %esi,%edx
f0100d58:	7d 49                	jge    f0100da3 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
f0100d5a:	83 c2 01             	add    $0x1,%edx
f0100d5d:	89 d0                	mov    %edx,%eax
f0100d5f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d62:	8d 14 95 5c 21 10 f0 	lea    -0xfefdea4(,%edx,4),%edx
f0100d69:	eb 04                	jmp    f0100d6f <debuginfo_eip+0x1e2>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d6b:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d6f:	39 c6                	cmp    %eax,%esi
f0100d71:	7e 2b                	jle    f0100d9e <debuginfo_eip+0x211>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d73:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100d77:	83 c0 01             	add    $0x1,%eax
f0100d7a:	83 c2 0c             	add    $0xc,%edx
f0100d7d:	80 f9 a0             	cmp    $0xa0,%cl
f0100d80:	74 e9                	je     f0100d6b <debuginfo_eip+0x1de>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d82:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d87:	eb 1a                	jmp    f0100da3 <debuginfo_eip+0x216>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d89:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d8e:	eb 13                	jmp    f0100da3 <debuginfo_eip+0x216>
f0100d90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d95:	eb 0c                	jmp    f0100da3 <debuginfo_eip+0x216>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d97:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d9c:	eb 05                	jmp    f0100da3 <debuginfo_eip+0x216>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d9e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100da3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100da6:	5b                   	pop    %ebx
f0100da7:	5e                   	pop    %esi
f0100da8:	5f                   	pop    %edi
f0100da9:	5d                   	pop    %ebp
f0100daa:	c3                   	ret    

f0100dab <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100dab:	55                   	push   %ebp
f0100dac:	89 e5                	mov    %esp,%ebp
f0100dae:	57                   	push   %edi
f0100daf:	56                   	push   %esi
f0100db0:	53                   	push   %ebx
f0100db1:	83 ec 1c             	sub    $0x1c,%esp
f0100db4:	89 c7                	mov    %eax,%edi
f0100db6:	89 d6                	mov    %edx,%esi
f0100db8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dbb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100dbe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100dc1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100dc4:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100dc7:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100dcc:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100dcf:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100dd2:	39 d3                	cmp    %edx,%ebx
f0100dd4:	72 05                	jb     f0100ddb <printnum+0x30>
f0100dd6:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100dd9:	77 45                	ja     f0100e20 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100ddb:	83 ec 0c             	sub    $0xc,%esp
f0100dde:	ff 75 18             	pushl  0x18(%ebp)
f0100de1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100de4:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100de7:	53                   	push   %ebx
f0100de8:	ff 75 10             	pushl  0x10(%ebp)
f0100deb:	83 ec 08             	sub    $0x8,%esp
f0100dee:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100df1:	ff 75 e0             	pushl  -0x20(%ebp)
f0100df4:	ff 75 dc             	pushl  -0x24(%ebp)
f0100df7:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dfa:	e8 31 09 00 00       	call   f0101730 <__udivdi3>
f0100dff:	83 c4 18             	add    $0x18,%esp
f0100e02:	52                   	push   %edx
f0100e03:	50                   	push   %eax
f0100e04:	89 f2                	mov    %esi,%edx
f0100e06:	89 f8                	mov    %edi,%eax
f0100e08:	e8 9e ff ff ff       	call   f0100dab <printnum>
f0100e0d:	83 c4 20             	add    $0x20,%esp
f0100e10:	eb 18                	jmp    f0100e2a <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e12:	83 ec 08             	sub    $0x8,%esp
f0100e15:	56                   	push   %esi
f0100e16:	ff 75 18             	pushl  0x18(%ebp)
f0100e19:	ff d7                	call   *%edi
f0100e1b:	83 c4 10             	add    $0x10,%esp
f0100e1e:	eb 03                	jmp    f0100e23 <printnum+0x78>
f0100e20:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e23:	83 eb 01             	sub    $0x1,%ebx
f0100e26:	85 db                	test   %ebx,%ebx
f0100e28:	7f e8                	jg     f0100e12 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e2a:	83 ec 08             	sub    $0x8,%esp
f0100e2d:	56                   	push   %esi
f0100e2e:	83 ec 04             	sub    $0x4,%esp
f0100e31:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100e34:	ff 75 e0             	pushl  -0x20(%ebp)
f0100e37:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e3a:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e3d:	e8 1e 0a 00 00       	call   f0101860 <__umoddi3>
f0100e42:	83 c4 14             	add    $0x14,%esp
f0100e45:	0f be 80 49 1f 10 f0 	movsbl -0xfefe0b7(%eax),%eax
f0100e4c:	50                   	push   %eax
f0100e4d:	ff d7                	call   *%edi
}
f0100e4f:	83 c4 10             	add    $0x10,%esp
f0100e52:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e55:	5b                   	pop    %ebx
f0100e56:	5e                   	pop    %esi
f0100e57:	5f                   	pop    %edi
f0100e58:	5d                   	pop    %ebp
f0100e59:	c3                   	ret    

f0100e5a <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e5a:	55                   	push   %ebp
f0100e5b:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e5d:	83 fa 01             	cmp    $0x1,%edx
f0100e60:	7e 0e                	jle    f0100e70 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e62:	8b 10                	mov    (%eax),%edx
f0100e64:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100e67:	89 08                	mov    %ecx,(%eax)
f0100e69:	8b 02                	mov    (%edx),%eax
f0100e6b:	8b 52 04             	mov    0x4(%edx),%edx
f0100e6e:	eb 22                	jmp    f0100e92 <getuint+0x38>
	else if (lflag)
f0100e70:	85 d2                	test   %edx,%edx
f0100e72:	74 10                	je     f0100e84 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e74:	8b 10                	mov    (%eax),%edx
f0100e76:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e79:	89 08                	mov    %ecx,(%eax)
f0100e7b:	8b 02                	mov    (%edx),%eax
f0100e7d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e82:	eb 0e                	jmp    f0100e92 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e84:	8b 10                	mov    (%eax),%edx
f0100e86:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e89:	89 08                	mov    %ecx,(%eax)
f0100e8b:	8b 02                	mov    (%edx),%eax
f0100e8d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e92:	5d                   	pop    %ebp
f0100e93:	c3                   	ret    

f0100e94 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0100e94:	55                   	push   %ebp
f0100e95:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e97:	83 fa 01             	cmp    $0x1,%edx
f0100e9a:	7e 0e                	jle    f0100eaa <getint+0x16>
		return va_arg(*ap, long long);
f0100e9c:	8b 10                	mov    (%eax),%edx
f0100e9e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100ea1:	89 08                	mov    %ecx,(%eax)
f0100ea3:	8b 02                	mov    (%edx),%eax
f0100ea5:	8b 52 04             	mov    0x4(%edx),%edx
f0100ea8:	eb 1a                	jmp    f0100ec4 <getint+0x30>
	else if (lflag)
f0100eaa:	85 d2                	test   %edx,%edx
f0100eac:	74 0c                	je     f0100eba <getint+0x26>
		return va_arg(*ap, long);
f0100eae:	8b 10                	mov    (%eax),%edx
f0100eb0:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eb3:	89 08                	mov    %ecx,(%eax)
f0100eb5:	8b 02                	mov    (%edx),%eax
f0100eb7:	99                   	cltd   
f0100eb8:	eb 0a                	jmp    f0100ec4 <getint+0x30>
	else
		return va_arg(*ap, int);
f0100eba:	8b 10                	mov    (%eax),%edx
f0100ebc:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ebf:	89 08                	mov    %ecx,(%eax)
f0100ec1:	8b 02                	mov    (%edx),%eax
f0100ec3:	99                   	cltd   
}
f0100ec4:	5d                   	pop    %ebp
f0100ec5:	c3                   	ret    

f0100ec6 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ec6:	55                   	push   %ebp
f0100ec7:	89 e5                	mov    %esp,%ebp
f0100ec9:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ecc:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ed0:	8b 10                	mov    (%eax),%edx
f0100ed2:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ed5:	73 0a                	jae    f0100ee1 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ed7:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100eda:	89 08                	mov    %ecx,(%eax)
f0100edc:	8b 45 08             	mov    0x8(%ebp),%eax
f0100edf:	88 02                	mov    %al,(%edx)
}
f0100ee1:	5d                   	pop    %ebp
f0100ee2:	c3                   	ret    

f0100ee3 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ee3:	55                   	push   %ebp
f0100ee4:	89 e5                	mov    %esp,%ebp
f0100ee6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ee9:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100eec:	50                   	push   %eax
f0100eed:	ff 75 10             	pushl  0x10(%ebp)
f0100ef0:	ff 75 0c             	pushl  0xc(%ebp)
f0100ef3:	ff 75 08             	pushl  0x8(%ebp)
f0100ef6:	e8 05 00 00 00       	call   f0100f00 <vprintfmt>
	va_end(ap);
}
f0100efb:	83 c4 10             	add    $0x10,%esp
f0100efe:	c9                   	leave  
f0100eff:	c3                   	ret    

f0100f00 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f00:	55                   	push   %ebp
f0100f01:	89 e5                	mov    %esp,%ebp
f0100f03:	57                   	push   %edi
f0100f04:	56                   	push   %esi
f0100f05:	53                   	push   %ebx
f0100f06:	83 ec 2c             	sub    $0x2c,%esp
f0100f09:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f0c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f0f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100f12:	eb 12                	jmp    f0100f26 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f14:	85 c0                	test   %eax,%eax
f0100f16:	0f 84 44 03 00 00    	je     f0101260 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0100f1c:	83 ec 08             	sub    $0x8,%esp
f0100f1f:	53                   	push   %ebx
f0100f20:	50                   	push   %eax
f0100f21:	ff d6                	call   *%esi
f0100f23:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f26:	83 c7 01             	add    $0x1,%edi
f0100f29:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f2d:	83 f8 25             	cmp    $0x25,%eax
f0100f30:	75 e2                	jne    f0100f14 <vprintfmt+0x14>
f0100f32:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100f36:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f3d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f44:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100f4b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f50:	eb 07                	jmp    f0100f59 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f52:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f55:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f59:	8d 47 01             	lea    0x1(%edi),%eax
f0100f5c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f5f:	0f b6 07             	movzbl (%edi),%eax
f0100f62:	0f b6 c8             	movzbl %al,%ecx
f0100f65:	83 e8 23             	sub    $0x23,%eax
f0100f68:	3c 55                	cmp    $0x55,%al
f0100f6a:	0f 87 d5 02 00 00    	ja     f0101245 <vprintfmt+0x345>
f0100f70:	0f b6 c0             	movzbl %al,%eax
f0100f73:	ff 24 85 d8 1f 10 f0 	jmp    *-0xfefe028(,%eax,4)
f0100f7a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f7d:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f81:	eb d6                	jmp    f0100f59 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f86:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f8b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f8e:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f91:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0100f95:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0100f98:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100f9b:	83 fa 09             	cmp    $0x9,%edx
f0100f9e:	77 39                	ja     f0100fd9 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100fa0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100fa3:	eb e9                	jmp    f0100f8e <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fa5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa8:	8d 48 04             	lea    0x4(%eax),%ecx
f0100fab:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100fae:	8b 00                	mov    (%eax),%eax
f0100fb0:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fb6:	eb 27                	jmp    f0100fdf <vprintfmt+0xdf>
f0100fb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fbb:	85 c0                	test   %eax,%eax
f0100fbd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100fc2:	0f 49 c8             	cmovns %eax,%ecx
f0100fc5:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fcb:	eb 8c                	jmp    f0100f59 <vprintfmt+0x59>
f0100fcd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fd0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fd7:	eb 80                	jmp    f0100f59 <vprintfmt+0x59>
f0100fd9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100fdc:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100fdf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fe3:	0f 89 70 ff ff ff    	jns    f0100f59 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100fe9:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100fec:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fef:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ff6:	e9 5e ff ff ff       	jmp    f0100f59 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100ffb:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101001:	e9 53 ff ff ff       	jmp    f0100f59 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101006:	8b 45 14             	mov    0x14(%ebp),%eax
f0101009:	8d 50 04             	lea    0x4(%eax),%edx
f010100c:	89 55 14             	mov    %edx,0x14(%ebp)
f010100f:	83 ec 08             	sub    $0x8,%esp
f0101012:	53                   	push   %ebx
f0101013:	ff 30                	pushl  (%eax)
f0101015:	ff d6                	call   *%esi
			break;
f0101017:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010101a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010101d:	e9 04 ff ff ff       	jmp    f0100f26 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101022:	8b 45 14             	mov    0x14(%ebp),%eax
f0101025:	8d 50 04             	lea    0x4(%eax),%edx
f0101028:	89 55 14             	mov    %edx,0x14(%ebp)
f010102b:	8b 00                	mov    (%eax),%eax
f010102d:	99                   	cltd   
f010102e:	31 d0                	xor    %edx,%eax
f0101030:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101032:	83 f8 06             	cmp    $0x6,%eax
f0101035:	7f 0b                	jg     f0101042 <vprintfmt+0x142>
f0101037:	8b 14 85 30 21 10 f0 	mov    -0xfefded0(,%eax,4),%edx
f010103e:	85 d2                	test   %edx,%edx
f0101040:	75 18                	jne    f010105a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101042:	50                   	push   %eax
f0101043:	68 61 1f 10 f0       	push   $0xf0101f61
f0101048:	53                   	push   %ebx
f0101049:	56                   	push   %esi
f010104a:	e8 94 fe ff ff       	call   f0100ee3 <printfmt>
f010104f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101052:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101055:	e9 cc fe ff ff       	jmp    f0100f26 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f010105a:	52                   	push   %edx
f010105b:	68 6a 1f 10 f0       	push   $0xf0101f6a
f0101060:	53                   	push   %ebx
f0101061:	56                   	push   %esi
f0101062:	e8 7c fe ff ff       	call   f0100ee3 <printfmt>
f0101067:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010106a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010106d:	e9 b4 fe ff ff       	jmp    f0100f26 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101072:	8b 45 14             	mov    0x14(%ebp),%eax
f0101075:	8d 50 04             	lea    0x4(%eax),%edx
f0101078:	89 55 14             	mov    %edx,0x14(%ebp)
f010107b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010107d:	85 ff                	test   %edi,%edi
f010107f:	b8 5a 1f 10 f0       	mov    $0xf0101f5a,%eax
f0101084:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101087:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010108b:	0f 8e 94 00 00 00    	jle    f0101125 <vprintfmt+0x225>
f0101091:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101095:	0f 84 98 00 00 00    	je     f0101133 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f010109b:	83 ec 08             	sub    $0x8,%esp
f010109e:	ff 75 d0             	pushl  -0x30(%ebp)
f01010a1:	57                   	push   %edi
f01010a2:	e8 1a 03 00 00       	call   f01013c1 <strnlen>
f01010a7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01010aa:	29 c1                	sub    %eax,%ecx
f01010ac:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01010af:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01010b2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01010b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010b9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01010bc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010be:	eb 0f                	jmp    f01010cf <vprintfmt+0x1cf>
					putch(padc, putdat);
f01010c0:	83 ec 08             	sub    $0x8,%esp
f01010c3:	53                   	push   %ebx
f01010c4:	ff 75 e0             	pushl  -0x20(%ebp)
f01010c7:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010c9:	83 ef 01             	sub    $0x1,%edi
f01010cc:	83 c4 10             	add    $0x10,%esp
f01010cf:	85 ff                	test   %edi,%edi
f01010d1:	7f ed                	jg     f01010c0 <vprintfmt+0x1c0>
f01010d3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01010d6:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01010d9:	85 c9                	test   %ecx,%ecx
f01010db:	b8 00 00 00 00       	mov    $0x0,%eax
f01010e0:	0f 49 c1             	cmovns %ecx,%eax
f01010e3:	29 c1                	sub    %eax,%ecx
f01010e5:	89 75 08             	mov    %esi,0x8(%ebp)
f01010e8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010eb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010ee:	89 cb                	mov    %ecx,%ebx
f01010f0:	eb 4d                	jmp    f010113f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010f2:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010f6:	74 1b                	je     f0101113 <vprintfmt+0x213>
f01010f8:	0f be c0             	movsbl %al,%eax
f01010fb:	83 e8 20             	sub    $0x20,%eax
f01010fe:	83 f8 5e             	cmp    $0x5e,%eax
f0101101:	76 10                	jbe    f0101113 <vprintfmt+0x213>
					putch('?', putdat);
f0101103:	83 ec 08             	sub    $0x8,%esp
f0101106:	ff 75 0c             	pushl  0xc(%ebp)
f0101109:	6a 3f                	push   $0x3f
f010110b:	ff 55 08             	call   *0x8(%ebp)
f010110e:	83 c4 10             	add    $0x10,%esp
f0101111:	eb 0d                	jmp    f0101120 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101113:	83 ec 08             	sub    $0x8,%esp
f0101116:	ff 75 0c             	pushl  0xc(%ebp)
f0101119:	52                   	push   %edx
f010111a:	ff 55 08             	call   *0x8(%ebp)
f010111d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101120:	83 eb 01             	sub    $0x1,%ebx
f0101123:	eb 1a                	jmp    f010113f <vprintfmt+0x23f>
f0101125:	89 75 08             	mov    %esi,0x8(%ebp)
f0101128:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010112b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010112e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101131:	eb 0c                	jmp    f010113f <vprintfmt+0x23f>
f0101133:	89 75 08             	mov    %esi,0x8(%ebp)
f0101136:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101139:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010113c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010113f:	83 c7 01             	add    $0x1,%edi
f0101142:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101146:	0f be d0             	movsbl %al,%edx
f0101149:	85 d2                	test   %edx,%edx
f010114b:	74 23                	je     f0101170 <vprintfmt+0x270>
f010114d:	85 f6                	test   %esi,%esi
f010114f:	78 a1                	js     f01010f2 <vprintfmt+0x1f2>
f0101151:	83 ee 01             	sub    $0x1,%esi
f0101154:	79 9c                	jns    f01010f2 <vprintfmt+0x1f2>
f0101156:	89 df                	mov    %ebx,%edi
f0101158:	8b 75 08             	mov    0x8(%ebp),%esi
f010115b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010115e:	eb 18                	jmp    f0101178 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101160:	83 ec 08             	sub    $0x8,%esp
f0101163:	53                   	push   %ebx
f0101164:	6a 20                	push   $0x20
f0101166:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101168:	83 ef 01             	sub    $0x1,%edi
f010116b:	83 c4 10             	add    $0x10,%esp
f010116e:	eb 08                	jmp    f0101178 <vprintfmt+0x278>
f0101170:	89 df                	mov    %ebx,%edi
f0101172:	8b 75 08             	mov    0x8(%ebp),%esi
f0101175:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101178:	85 ff                	test   %edi,%edi
f010117a:	7f e4                	jg     f0101160 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010117c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010117f:	e9 a2 fd ff ff       	jmp    f0100f26 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101184:	8d 45 14             	lea    0x14(%ebp),%eax
f0101187:	e8 08 fd ff ff       	call   f0100e94 <getint>
f010118c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010118f:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101192:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101197:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010119b:	79 74                	jns    f0101211 <vprintfmt+0x311>
				putch('-', putdat);
f010119d:	83 ec 08             	sub    $0x8,%esp
f01011a0:	53                   	push   %ebx
f01011a1:	6a 2d                	push   $0x2d
f01011a3:	ff d6                	call   *%esi
				num = -(long long) num;
f01011a5:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01011a8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011ab:	f7 d8                	neg    %eax
f01011ad:	83 d2 00             	adc    $0x0,%edx
f01011b0:	f7 da                	neg    %edx
f01011b2:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01011b5:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01011ba:	eb 55                	jmp    f0101211 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01011bc:	8d 45 14             	lea    0x14(%ebp),%eax
f01011bf:	e8 96 fc ff ff       	call   f0100e5a <getuint>
			base = 10;
f01011c4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011c9:	eb 46                	jmp    f0101211 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f01011cb:	8d 45 14             	lea    0x14(%ebp),%eax
f01011ce:	e8 87 fc ff ff       	call   f0100e5a <getuint>
			base = 8;
f01011d3:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01011d8:	eb 37                	jmp    f0101211 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f01011da:	83 ec 08             	sub    $0x8,%esp
f01011dd:	53                   	push   %ebx
f01011de:	6a 30                	push   $0x30
f01011e0:	ff d6                	call   *%esi
			putch('x', putdat);
f01011e2:	83 c4 08             	add    $0x8,%esp
f01011e5:	53                   	push   %ebx
f01011e6:	6a 78                	push   $0x78
f01011e8:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01011ea:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ed:	8d 50 04             	lea    0x4(%eax),%edx
f01011f0:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01011f3:	8b 00                	mov    (%eax),%eax
f01011f5:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01011fa:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01011fd:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101202:	eb 0d                	jmp    f0101211 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101204:	8d 45 14             	lea    0x14(%ebp),%eax
f0101207:	e8 4e fc ff ff       	call   f0100e5a <getuint>
			base = 16;
f010120c:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101211:	83 ec 0c             	sub    $0xc,%esp
f0101214:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101218:	57                   	push   %edi
f0101219:	ff 75 e0             	pushl  -0x20(%ebp)
f010121c:	51                   	push   %ecx
f010121d:	52                   	push   %edx
f010121e:	50                   	push   %eax
f010121f:	89 da                	mov    %ebx,%edx
f0101221:	89 f0                	mov    %esi,%eax
f0101223:	e8 83 fb ff ff       	call   f0100dab <printnum>
			break;
f0101228:	83 c4 20             	add    $0x20,%esp
f010122b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010122e:	e9 f3 fc ff ff       	jmp    f0100f26 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101233:	83 ec 08             	sub    $0x8,%esp
f0101236:	53                   	push   %ebx
f0101237:	51                   	push   %ecx
f0101238:	ff d6                	call   *%esi
			break;
f010123a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010123d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101240:	e9 e1 fc ff ff       	jmp    f0100f26 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101245:	83 ec 08             	sub    $0x8,%esp
f0101248:	53                   	push   %ebx
f0101249:	6a 25                	push   $0x25
f010124b:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010124d:	83 c4 10             	add    $0x10,%esp
f0101250:	eb 03                	jmp    f0101255 <vprintfmt+0x355>
f0101252:	83 ef 01             	sub    $0x1,%edi
f0101255:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101259:	75 f7                	jne    f0101252 <vprintfmt+0x352>
f010125b:	e9 c6 fc ff ff       	jmp    f0100f26 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101260:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101263:	5b                   	pop    %ebx
f0101264:	5e                   	pop    %esi
f0101265:	5f                   	pop    %edi
f0101266:	5d                   	pop    %ebp
f0101267:	c3                   	ret    

f0101268 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101268:	55                   	push   %ebp
f0101269:	89 e5                	mov    %esp,%ebp
f010126b:	83 ec 18             	sub    $0x18,%esp
f010126e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101271:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101274:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101277:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010127b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010127e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101285:	85 c0                	test   %eax,%eax
f0101287:	74 26                	je     f01012af <vsnprintf+0x47>
f0101289:	85 d2                	test   %edx,%edx
f010128b:	7e 22                	jle    f01012af <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010128d:	ff 75 14             	pushl  0x14(%ebp)
f0101290:	ff 75 10             	pushl  0x10(%ebp)
f0101293:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101296:	50                   	push   %eax
f0101297:	68 c6 0e 10 f0       	push   $0xf0100ec6
f010129c:	e8 5f fc ff ff       	call   f0100f00 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012a4:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012aa:	83 c4 10             	add    $0x10,%esp
f01012ad:	eb 05                	jmp    f01012b4 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012af:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01012b4:	c9                   	leave  
f01012b5:	c3                   	ret    

f01012b6 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012b6:	55                   	push   %ebp
f01012b7:	89 e5                	mov    %esp,%ebp
f01012b9:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012bc:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012bf:	50                   	push   %eax
f01012c0:	ff 75 10             	pushl  0x10(%ebp)
f01012c3:	ff 75 0c             	pushl  0xc(%ebp)
f01012c6:	ff 75 08             	pushl  0x8(%ebp)
f01012c9:	e8 9a ff ff ff       	call   f0101268 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012ce:	c9                   	leave  
f01012cf:	c3                   	ret    

f01012d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	57                   	push   %edi
f01012d4:	56                   	push   %esi
f01012d5:	53                   	push   %ebx
f01012d6:	83 ec 0c             	sub    $0xc,%esp
f01012d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012dc:	85 c0                	test   %eax,%eax
f01012de:	74 11                	je     f01012f1 <readline+0x21>
		cprintf("%s", prompt);
f01012e0:	83 ec 08             	sub    $0x8,%esp
f01012e3:	50                   	push   %eax
f01012e4:	68 6a 1f 10 f0       	push   $0xf0101f6a
f01012e9:	e8 95 f7 ff ff       	call   f0100a83 <cprintf>
f01012ee:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01012f1:	83 ec 0c             	sub    $0xc,%esp
f01012f4:	6a 00                	push   $0x0
f01012f6:	e8 86 f4 ff ff       	call   f0100781 <iscons>
f01012fb:	89 c7                	mov    %eax,%edi
f01012fd:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101300:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101305:	e8 66 f4 ff ff       	call   f0100770 <getchar>
f010130a:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010130c:	85 c0                	test   %eax,%eax
f010130e:	79 18                	jns    f0101328 <readline+0x58>
			cprintf("read error: %e\n", c);
f0101310:	83 ec 08             	sub    $0x8,%esp
f0101313:	50                   	push   %eax
f0101314:	68 4c 21 10 f0       	push   $0xf010214c
f0101319:	e8 65 f7 ff ff       	call   f0100a83 <cprintf>
			return NULL;
f010131e:	83 c4 10             	add    $0x10,%esp
f0101321:	b8 00 00 00 00       	mov    $0x0,%eax
f0101326:	eb 79                	jmp    f01013a1 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101328:	83 f8 08             	cmp    $0x8,%eax
f010132b:	0f 94 c2             	sete   %dl
f010132e:	83 f8 7f             	cmp    $0x7f,%eax
f0101331:	0f 94 c0             	sete   %al
f0101334:	08 c2                	or     %al,%dl
f0101336:	74 1a                	je     f0101352 <readline+0x82>
f0101338:	85 f6                	test   %esi,%esi
f010133a:	7e 16                	jle    f0101352 <readline+0x82>
			if (echoing)
f010133c:	85 ff                	test   %edi,%edi
f010133e:	74 0d                	je     f010134d <readline+0x7d>
				cputchar('\b');
f0101340:	83 ec 0c             	sub    $0xc,%esp
f0101343:	6a 08                	push   $0x8
f0101345:	e8 16 f4 ff ff       	call   f0100760 <cputchar>
f010134a:	83 c4 10             	add    $0x10,%esp
			i--;
f010134d:	83 ee 01             	sub    $0x1,%esi
f0101350:	eb b3                	jmp    f0101305 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101352:	83 fb 1f             	cmp    $0x1f,%ebx
f0101355:	7e 23                	jle    f010137a <readline+0xaa>
f0101357:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010135d:	7f 1b                	jg     f010137a <readline+0xaa>
			if (echoing)
f010135f:	85 ff                	test   %edi,%edi
f0101361:	74 0c                	je     f010136f <readline+0x9f>
				cputchar(c);
f0101363:	83 ec 0c             	sub    $0xc,%esp
f0101366:	53                   	push   %ebx
f0101367:	e8 f4 f3 ff ff       	call   f0100760 <cputchar>
f010136c:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010136f:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101375:	8d 76 01             	lea    0x1(%esi),%esi
f0101378:	eb 8b                	jmp    f0101305 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010137a:	83 fb 0a             	cmp    $0xa,%ebx
f010137d:	74 05                	je     f0101384 <readline+0xb4>
f010137f:	83 fb 0d             	cmp    $0xd,%ebx
f0101382:	75 81                	jne    f0101305 <readline+0x35>
			if (echoing)
f0101384:	85 ff                	test   %edi,%edi
f0101386:	74 0d                	je     f0101395 <readline+0xc5>
				cputchar('\n');
f0101388:	83 ec 0c             	sub    $0xc,%esp
f010138b:	6a 0a                	push   $0xa
f010138d:	e8 ce f3 ff ff       	call   f0100760 <cputchar>
f0101392:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101395:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010139c:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013a1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013a4:	5b                   	pop    %ebx
f01013a5:	5e                   	pop    %esi
f01013a6:	5f                   	pop    %edi
f01013a7:	5d                   	pop    %ebp
f01013a8:	c3                   	ret    

f01013a9 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013a9:	55                   	push   %ebp
f01013aa:	89 e5                	mov    %esp,%ebp
f01013ac:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013af:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b4:	eb 03                	jmp    f01013b9 <strlen+0x10>
		n++;
f01013b6:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b9:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013bd:	75 f7                	jne    f01013b6 <strlen+0xd>
		n++;
	return n;
}
f01013bf:	5d                   	pop    %ebp
f01013c0:	c3                   	ret    

f01013c1 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013c1:	55                   	push   %ebp
f01013c2:	89 e5                	mov    %esp,%ebp
f01013c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013c7:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013ca:	ba 00 00 00 00       	mov    $0x0,%edx
f01013cf:	eb 03                	jmp    f01013d4 <strnlen+0x13>
		n++;
f01013d1:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013d4:	39 c2                	cmp    %eax,%edx
f01013d6:	74 08                	je     f01013e0 <strnlen+0x1f>
f01013d8:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01013dc:	75 f3                	jne    f01013d1 <strnlen+0x10>
f01013de:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01013e0:	5d                   	pop    %ebp
f01013e1:	c3                   	ret    

f01013e2 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013e2:	55                   	push   %ebp
f01013e3:	89 e5                	mov    %esp,%ebp
f01013e5:	53                   	push   %ebx
f01013e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013ec:	89 c2                	mov    %eax,%edx
f01013ee:	83 c2 01             	add    $0x1,%edx
f01013f1:	83 c1 01             	add    $0x1,%ecx
f01013f4:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01013f8:	88 5a ff             	mov    %bl,-0x1(%edx)
f01013fb:	84 db                	test   %bl,%bl
f01013fd:	75 ef                	jne    f01013ee <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01013ff:	5b                   	pop    %ebx
f0101400:	5d                   	pop    %ebp
f0101401:	c3                   	ret    

f0101402 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101402:	55                   	push   %ebp
f0101403:	89 e5                	mov    %esp,%ebp
f0101405:	53                   	push   %ebx
f0101406:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101409:	53                   	push   %ebx
f010140a:	e8 9a ff ff ff       	call   f01013a9 <strlen>
f010140f:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101412:	ff 75 0c             	pushl  0xc(%ebp)
f0101415:	01 d8                	add    %ebx,%eax
f0101417:	50                   	push   %eax
f0101418:	e8 c5 ff ff ff       	call   f01013e2 <strcpy>
	return dst;
}
f010141d:	89 d8                	mov    %ebx,%eax
f010141f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101422:	c9                   	leave  
f0101423:	c3                   	ret    

f0101424 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101424:	55                   	push   %ebp
f0101425:	89 e5                	mov    %esp,%ebp
f0101427:	56                   	push   %esi
f0101428:	53                   	push   %ebx
f0101429:	8b 75 08             	mov    0x8(%ebp),%esi
f010142c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010142f:	89 f3                	mov    %esi,%ebx
f0101431:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101434:	89 f2                	mov    %esi,%edx
f0101436:	eb 0f                	jmp    f0101447 <strncpy+0x23>
		*dst++ = *src;
f0101438:	83 c2 01             	add    $0x1,%edx
f010143b:	0f b6 01             	movzbl (%ecx),%eax
f010143e:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101441:	80 39 01             	cmpb   $0x1,(%ecx)
f0101444:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101447:	39 da                	cmp    %ebx,%edx
f0101449:	75 ed                	jne    f0101438 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010144b:	89 f0                	mov    %esi,%eax
f010144d:	5b                   	pop    %ebx
f010144e:	5e                   	pop    %esi
f010144f:	5d                   	pop    %ebp
f0101450:	c3                   	ret    

f0101451 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101451:	55                   	push   %ebp
f0101452:	89 e5                	mov    %esp,%ebp
f0101454:	56                   	push   %esi
f0101455:	53                   	push   %ebx
f0101456:	8b 75 08             	mov    0x8(%ebp),%esi
f0101459:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010145c:	8b 55 10             	mov    0x10(%ebp),%edx
f010145f:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101461:	85 d2                	test   %edx,%edx
f0101463:	74 21                	je     f0101486 <strlcpy+0x35>
f0101465:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101469:	89 f2                	mov    %esi,%edx
f010146b:	eb 09                	jmp    f0101476 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010146d:	83 c2 01             	add    $0x1,%edx
f0101470:	83 c1 01             	add    $0x1,%ecx
f0101473:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101476:	39 c2                	cmp    %eax,%edx
f0101478:	74 09                	je     f0101483 <strlcpy+0x32>
f010147a:	0f b6 19             	movzbl (%ecx),%ebx
f010147d:	84 db                	test   %bl,%bl
f010147f:	75 ec                	jne    f010146d <strlcpy+0x1c>
f0101481:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101483:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101486:	29 f0                	sub    %esi,%eax
}
f0101488:	5b                   	pop    %ebx
f0101489:	5e                   	pop    %esi
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    

f010148c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010148c:	55                   	push   %ebp
f010148d:	89 e5                	mov    %esp,%ebp
f010148f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101492:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101495:	eb 06                	jmp    f010149d <strcmp+0x11>
		p++, q++;
f0101497:	83 c1 01             	add    $0x1,%ecx
f010149a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010149d:	0f b6 01             	movzbl (%ecx),%eax
f01014a0:	84 c0                	test   %al,%al
f01014a2:	74 04                	je     f01014a8 <strcmp+0x1c>
f01014a4:	3a 02                	cmp    (%edx),%al
f01014a6:	74 ef                	je     f0101497 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014a8:	0f b6 c0             	movzbl %al,%eax
f01014ab:	0f b6 12             	movzbl (%edx),%edx
f01014ae:	29 d0                	sub    %edx,%eax
}
f01014b0:	5d                   	pop    %ebp
f01014b1:	c3                   	ret    

f01014b2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014b2:	55                   	push   %ebp
f01014b3:	89 e5                	mov    %esp,%ebp
f01014b5:	53                   	push   %ebx
f01014b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014bc:	89 c3                	mov    %eax,%ebx
f01014be:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014c1:	eb 06                	jmp    f01014c9 <strncmp+0x17>
		n--, p++, q++;
f01014c3:	83 c0 01             	add    $0x1,%eax
f01014c6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01014c9:	39 d8                	cmp    %ebx,%eax
f01014cb:	74 15                	je     f01014e2 <strncmp+0x30>
f01014cd:	0f b6 08             	movzbl (%eax),%ecx
f01014d0:	84 c9                	test   %cl,%cl
f01014d2:	74 04                	je     f01014d8 <strncmp+0x26>
f01014d4:	3a 0a                	cmp    (%edx),%cl
f01014d6:	74 eb                	je     f01014c3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014d8:	0f b6 00             	movzbl (%eax),%eax
f01014db:	0f b6 12             	movzbl (%edx),%edx
f01014de:	29 d0                	sub    %edx,%eax
f01014e0:	eb 05                	jmp    f01014e7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01014e2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01014e7:	5b                   	pop    %ebx
f01014e8:	5d                   	pop    %ebp
f01014e9:	c3                   	ret    

f01014ea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014ea:	55                   	push   %ebp
f01014eb:	89 e5                	mov    %esp,%ebp
f01014ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014f4:	eb 07                	jmp    f01014fd <strchr+0x13>
		if (*s == c)
f01014f6:	38 ca                	cmp    %cl,%dl
f01014f8:	74 0f                	je     f0101509 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014fa:	83 c0 01             	add    $0x1,%eax
f01014fd:	0f b6 10             	movzbl (%eax),%edx
f0101500:	84 d2                	test   %dl,%dl
f0101502:	75 f2                	jne    f01014f6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101504:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101509:	5d                   	pop    %ebp
f010150a:	c3                   	ret    

f010150b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010150b:	55                   	push   %ebp
f010150c:	89 e5                	mov    %esp,%ebp
f010150e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101511:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101515:	eb 03                	jmp    f010151a <strfind+0xf>
f0101517:	83 c0 01             	add    $0x1,%eax
f010151a:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010151d:	38 ca                	cmp    %cl,%dl
f010151f:	74 04                	je     f0101525 <strfind+0x1a>
f0101521:	84 d2                	test   %dl,%dl
f0101523:	75 f2                	jne    f0101517 <strfind+0xc>
			break;
	return (char *) s;
}
f0101525:	5d                   	pop    %ebp
f0101526:	c3                   	ret    

f0101527 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101527:	55                   	push   %ebp
f0101528:	89 e5                	mov    %esp,%ebp
f010152a:	57                   	push   %edi
f010152b:	56                   	push   %esi
f010152c:	53                   	push   %ebx
f010152d:	8b 55 08             	mov    0x8(%ebp),%edx
f0101530:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0101533:	85 c9                	test   %ecx,%ecx
f0101535:	74 37                	je     f010156e <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101537:	f6 c2 03             	test   $0x3,%dl
f010153a:	75 2a                	jne    f0101566 <memset+0x3f>
f010153c:	f6 c1 03             	test   $0x3,%cl
f010153f:	75 25                	jne    f0101566 <memset+0x3f>
		c &= 0xFF;
f0101541:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101545:	89 df                	mov    %ebx,%edi
f0101547:	c1 e7 08             	shl    $0x8,%edi
f010154a:	89 de                	mov    %ebx,%esi
f010154c:	c1 e6 18             	shl    $0x18,%esi
f010154f:	89 d8                	mov    %ebx,%eax
f0101551:	c1 e0 10             	shl    $0x10,%eax
f0101554:	09 f0                	or     %esi,%eax
f0101556:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0101558:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010155b:	89 f8                	mov    %edi,%eax
f010155d:	09 d8                	or     %ebx,%eax
f010155f:	89 d7                	mov    %edx,%edi
f0101561:	fc                   	cld    
f0101562:	f3 ab                	rep stos %eax,%es:(%edi)
f0101564:	eb 08                	jmp    f010156e <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101566:	89 d7                	mov    %edx,%edi
f0101568:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156b:	fc                   	cld    
f010156c:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f010156e:	89 d0                	mov    %edx,%eax
f0101570:	5b                   	pop    %ebx
f0101571:	5e                   	pop    %esi
f0101572:	5f                   	pop    %edi
f0101573:	5d                   	pop    %ebp
f0101574:	c3                   	ret    

f0101575 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101575:	55                   	push   %ebp
f0101576:	89 e5                	mov    %esp,%ebp
f0101578:	57                   	push   %edi
f0101579:	56                   	push   %esi
f010157a:	8b 45 08             	mov    0x8(%ebp),%eax
f010157d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101580:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101583:	39 c6                	cmp    %eax,%esi
f0101585:	73 35                	jae    f01015bc <memmove+0x47>
f0101587:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010158a:	39 d0                	cmp    %edx,%eax
f010158c:	73 2e                	jae    f01015bc <memmove+0x47>
		s += n;
		d += n;
f010158e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101591:	89 d6                	mov    %edx,%esi
f0101593:	09 fe                	or     %edi,%esi
f0101595:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010159b:	75 13                	jne    f01015b0 <memmove+0x3b>
f010159d:	f6 c1 03             	test   $0x3,%cl
f01015a0:	75 0e                	jne    f01015b0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01015a2:	83 ef 04             	sub    $0x4,%edi
f01015a5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015a8:	c1 e9 02             	shr    $0x2,%ecx
f01015ab:	fd                   	std    
f01015ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015ae:	eb 09                	jmp    f01015b9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015b0:	83 ef 01             	sub    $0x1,%edi
f01015b3:	8d 72 ff             	lea    -0x1(%edx),%esi
f01015b6:	fd                   	std    
f01015b7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015b9:	fc                   	cld    
f01015ba:	eb 1d                	jmp    f01015d9 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015bc:	89 f2                	mov    %esi,%edx
f01015be:	09 c2                	or     %eax,%edx
f01015c0:	f6 c2 03             	test   $0x3,%dl
f01015c3:	75 0f                	jne    f01015d4 <memmove+0x5f>
f01015c5:	f6 c1 03             	test   $0x3,%cl
f01015c8:	75 0a                	jne    f01015d4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01015ca:	c1 e9 02             	shr    $0x2,%ecx
f01015cd:	89 c7                	mov    %eax,%edi
f01015cf:	fc                   	cld    
f01015d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015d2:	eb 05                	jmp    f01015d9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015d4:	89 c7                	mov    %eax,%edi
f01015d6:	fc                   	cld    
f01015d7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015d9:	5e                   	pop    %esi
f01015da:	5f                   	pop    %edi
f01015db:	5d                   	pop    %ebp
f01015dc:	c3                   	ret    

f01015dd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01015dd:	55                   	push   %ebp
f01015de:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01015e0:	ff 75 10             	pushl  0x10(%ebp)
f01015e3:	ff 75 0c             	pushl  0xc(%ebp)
f01015e6:	ff 75 08             	pushl  0x8(%ebp)
f01015e9:	e8 87 ff ff ff       	call   f0101575 <memmove>
}
f01015ee:	c9                   	leave  
f01015ef:	c3                   	ret    

f01015f0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015f0:	55                   	push   %ebp
f01015f1:	89 e5                	mov    %esp,%ebp
f01015f3:	56                   	push   %esi
f01015f4:	53                   	push   %ebx
f01015f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015fb:	89 c6                	mov    %eax,%esi
f01015fd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101600:	eb 1a                	jmp    f010161c <memcmp+0x2c>
		if (*s1 != *s2)
f0101602:	0f b6 08             	movzbl (%eax),%ecx
f0101605:	0f b6 1a             	movzbl (%edx),%ebx
f0101608:	38 d9                	cmp    %bl,%cl
f010160a:	74 0a                	je     f0101616 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010160c:	0f b6 c1             	movzbl %cl,%eax
f010160f:	0f b6 db             	movzbl %bl,%ebx
f0101612:	29 d8                	sub    %ebx,%eax
f0101614:	eb 0f                	jmp    f0101625 <memcmp+0x35>
		s1++, s2++;
f0101616:	83 c0 01             	add    $0x1,%eax
f0101619:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010161c:	39 f0                	cmp    %esi,%eax
f010161e:	75 e2                	jne    f0101602 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101620:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101625:	5b                   	pop    %ebx
f0101626:	5e                   	pop    %esi
f0101627:	5d                   	pop    %ebp
f0101628:	c3                   	ret    

f0101629 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101629:	55                   	push   %ebp
f010162a:	89 e5                	mov    %esp,%ebp
f010162c:	53                   	push   %ebx
f010162d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101630:	89 c1                	mov    %eax,%ecx
f0101632:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101635:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101639:	eb 0a                	jmp    f0101645 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010163b:	0f b6 10             	movzbl (%eax),%edx
f010163e:	39 da                	cmp    %ebx,%edx
f0101640:	74 07                	je     f0101649 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101642:	83 c0 01             	add    $0x1,%eax
f0101645:	39 c8                	cmp    %ecx,%eax
f0101647:	72 f2                	jb     f010163b <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101649:	5b                   	pop    %ebx
f010164a:	5d                   	pop    %ebp
f010164b:	c3                   	ret    

f010164c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010164c:	55                   	push   %ebp
f010164d:	89 e5                	mov    %esp,%ebp
f010164f:	57                   	push   %edi
f0101650:	56                   	push   %esi
f0101651:	53                   	push   %ebx
f0101652:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101655:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101658:	eb 03                	jmp    f010165d <strtol+0x11>
		s++;
f010165a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010165d:	0f b6 01             	movzbl (%ecx),%eax
f0101660:	3c 20                	cmp    $0x20,%al
f0101662:	74 f6                	je     f010165a <strtol+0xe>
f0101664:	3c 09                	cmp    $0x9,%al
f0101666:	74 f2                	je     f010165a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101668:	3c 2b                	cmp    $0x2b,%al
f010166a:	75 0a                	jne    f0101676 <strtol+0x2a>
		s++;
f010166c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010166f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101674:	eb 11                	jmp    f0101687 <strtol+0x3b>
f0101676:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010167b:	3c 2d                	cmp    $0x2d,%al
f010167d:	75 08                	jne    f0101687 <strtol+0x3b>
		s++, neg = 1;
f010167f:	83 c1 01             	add    $0x1,%ecx
f0101682:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101687:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010168d:	75 15                	jne    f01016a4 <strtol+0x58>
f010168f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101692:	75 10                	jne    f01016a4 <strtol+0x58>
f0101694:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101698:	75 7c                	jne    f0101716 <strtol+0xca>
		s += 2, base = 16;
f010169a:	83 c1 02             	add    $0x2,%ecx
f010169d:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016a2:	eb 16                	jmp    f01016ba <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01016a4:	85 db                	test   %ebx,%ebx
f01016a6:	75 12                	jne    f01016ba <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016a8:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016ad:	80 39 30             	cmpb   $0x30,(%ecx)
f01016b0:	75 08                	jne    f01016ba <strtol+0x6e>
		s++, base = 8;
f01016b2:	83 c1 01             	add    $0x1,%ecx
f01016b5:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01016ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01016bf:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016c2:	0f b6 11             	movzbl (%ecx),%edx
f01016c5:	8d 72 d0             	lea    -0x30(%edx),%esi
f01016c8:	89 f3                	mov    %esi,%ebx
f01016ca:	80 fb 09             	cmp    $0x9,%bl
f01016cd:	77 08                	ja     f01016d7 <strtol+0x8b>
			dig = *s - '0';
f01016cf:	0f be d2             	movsbl %dl,%edx
f01016d2:	83 ea 30             	sub    $0x30,%edx
f01016d5:	eb 22                	jmp    f01016f9 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01016d7:	8d 72 9f             	lea    -0x61(%edx),%esi
f01016da:	89 f3                	mov    %esi,%ebx
f01016dc:	80 fb 19             	cmp    $0x19,%bl
f01016df:	77 08                	ja     f01016e9 <strtol+0x9d>
			dig = *s - 'a' + 10;
f01016e1:	0f be d2             	movsbl %dl,%edx
f01016e4:	83 ea 57             	sub    $0x57,%edx
f01016e7:	eb 10                	jmp    f01016f9 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01016e9:	8d 72 bf             	lea    -0x41(%edx),%esi
f01016ec:	89 f3                	mov    %esi,%ebx
f01016ee:	80 fb 19             	cmp    $0x19,%bl
f01016f1:	77 16                	ja     f0101709 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01016f3:	0f be d2             	movsbl %dl,%edx
f01016f6:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01016f9:	3b 55 10             	cmp    0x10(%ebp),%edx
f01016fc:	7d 0b                	jge    f0101709 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01016fe:	83 c1 01             	add    $0x1,%ecx
f0101701:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101705:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101707:	eb b9                	jmp    f01016c2 <strtol+0x76>

	if (endptr)
f0101709:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010170d:	74 0d                	je     f010171c <strtol+0xd0>
		*endptr = (char *) s;
f010170f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101712:	89 0e                	mov    %ecx,(%esi)
f0101714:	eb 06                	jmp    f010171c <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101716:	85 db                	test   %ebx,%ebx
f0101718:	74 98                	je     f01016b2 <strtol+0x66>
f010171a:	eb 9e                	jmp    f01016ba <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010171c:	89 c2                	mov    %eax,%edx
f010171e:	f7 da                	neg    %edx
f0101720:	85 ff                	test   %edi,%edi
f0101722:	0f 45 c2             	cmovne %edx,%eax
}
f0101725:	5b                   	pop    %ebx
f0101726:	5e                   	pop    %esi
f0101727:	5f                   	pop    %edi
f0101728:	5d                   	pop    %ebp
f0101729:	c3                   	ret    
f010172a:	66 90                	xchg   %ax,%ax
f010172c:	66 90                	xchg   %ax,%ax
f010172e:	66 90                	xchg   %ax,%ax

f0101730 <__udivdi3>:
f0101730:	55                   	push   %ebp
f0101731:	57                   	push   %edi
f0101732:	56                   	push   %esi
f0101733:	53                   	push   %ebx
f0101734:	83 ec 1c             	sub    $0x1c,%esp
f0101737:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010173b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010173f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101743:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101747:	85 f6                	test   %esi,%esi
f0101749:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010174d:	89 ca                	mov    %ecx,%edx
f010174f:	89 f8                	mov    %edi,%eax
f0101751:	75 3d                	jne    f0101790 <__udivdi3+0x60>
f0101753:	39 cf                	cmp    %ecx,%edi
f0101755:	0f 87 c5 00 00 00    	ja     f0101820 <__udivdi3+0xf0>
f010175b:	85 ff                	test   %edi,%edi
f010175d:	89 fd                	mov    %edi,%ebp
f010175f:	75 0b                	jne    f010176c <__udivdi3+0x3c>
f0101761:	b8 01 00 00 00       	mov    $0x1,%eax
f0101766:	31 d2                	xor    %edx,%edx
f0101768:	f7 f7                	div    %edi
f010176a:	89 c5                	mov    %eax,%ebp
f010176c:	89 c8                	mov    %ecx,%eax
f010176e:	31 d2                	xor    %edx,%edx
f0101770:	f7 f5                	div    %ebp
f0101772:	89 c1                	mov    %eax,%ecx
f0101774:	89 d8                	mov    %ebx,%eax
f0101776:	89 cf                	mov    %ecx,%edi
f0101778:	f7 f5                	div    %ebp
f010177a:	89 c3                	mov    %eax,%ebx
f010177c:	89 d8                	mov    %ebx,%eax
f010177e:	89 fa                	mov    %edi,%edx
f0101780:	83 c4 1c             	add    $0x1c,%esp
f0101783:	5b                   	pop    %ebx
f0101784:	5e                   	pop    %esi
f0101785:	5f                   	pop    %edi
f0101786:	5d                   	pop    %ebp
f0101787:	c3                   	ret    
f0101788:	90                   	nop
f0101789:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101790:	39 ce                	cmp    %ecx,%esi
f0101792:	77 74                	ja     f0101808 <__udivdi3+0xd8>
f0101794:	0f bd fe             	bsr    %esi,%edi
f0101797:	83 f7 1f             	xor    $0x1f,%edi
f010179a:	0f 84 98 00 00 00    	je     f0101838 <__udivdi3+0x108>
f01017a0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01017a5:	89 f9                	mov    %edi,%ecx
f01017a7:	89 c5                	mov    %eax,%ebp
f01017a9:	29 fb                	sub    %edi,%ebx
f01017ab:	d3 e6                	shl    %cl,%esi
f01017ad:	89 d9                	mov    %ebx,%ecx
f01017af:	d3 ed                	shr    %cl,%ebp
f01017b1:	89 f9                	mov    %edi,%ecx
f01017b3:	d3 e0                	shl    %cl,%eax
f01017b5:	09 ee                	or     %ebp,%esi
f01017b7:	89 d9                	mov    %ebx,%ecx
f01017b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017bd:	89 d5                	mov    %edx,%ebp
f01017bf:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017c3:	d3 ed                	shr    %cl,%ebp
f01017c5:	89 f9                	mov    %edi,%ecx
f01017c7:	d3 e2                	shl    %cl,%edx
f01017c9:	89 d9                	mov    %ebx,%ecx
f01017cb:	d3 e8                	shr    %cl,%eax
f01017cd:	09 c2                	or     %eax,%edx
f01017cf:	89 d0                	mov    %edx,%eax
f01017d1:	89 ea                	mov    %ebp,%edx
f01017d3:	f7 f6                	div    %esi
f01017d5:	89 d5                	mov    %edx,%ebp
f01017d7:	89 c3                	mov    %eax,%ebx
f01017d9:	f7 64 24 0c          	mull   0xc(%esp)
f01017dd:	39 d5                	cmp    %edx,%ebp
f01017df:	72 10                	jb     f01017f1 <__udivdi3+0xc1>
f01017e1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01017e5:	89 f9                	mov    %edi,%ecx
f01017e7:	d3 e6                	shl    %cl,%esi
f01017e9:	39 c6                	cmp    %eax,%esi
f01017eb:	73 07                	jae    f01017f4 <__udivdi3+0xc4>
f01017ed:	39 d5                	cmp    %edx,%ebp
f01017ef:	75 03                	jne    f01017f4 <__udivdi3+0xc4>
f01017f1:	83 eb 01             	sub    $0x1,%ebx
f01017f4:	31 ff                	xor    %edi,%edi
f01017f6:	89 d8                	mov    %ebx,%eax
f01017f8:	89 fa                	mov    %edi,%edx
f01017fa:	83 c4 1c             	add    $0x1c,%esp
f01017fd:	5b                   	pop    %ebx
f01017fe:	5e                   	pop    %esi
f01017ff:	5f                   	pop    %edi
f0101800:	5d                   	pop    %ebp
f0101801:	c3                   	ret    
f0101802:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101808:	31 ff                	xor    %edi,%edi
f010180a:	31 db                	xor    %ebx,%ebx
f010180c:	89 d8                	mov    %ebx,%eax
f010180e:	89 fa                	mov    %edi,%edx
f0101810:	83 c4 1c             	add    $0x1c,%esp
f0101813:	5b                   	pop    %ebx
f0101814:	5e                   	pop    %esi
f0101815:	5f                   	pop    %edi
f0101816:	5d                   	pop    %ebp
f0101817:	c3                   	ret    
f0101818:	90                   	nop
f0101819:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101820:	89 d8                	mov    %ebx,%eax
f0101822:	f7 f7                	div    %edi
f0101824:	31 ff                	xor    %edi,%edi
f0101826:	89 c3                	mov    %eax,%ebx
f0101828:	89 d8                	mov    %ebx,%eax
f010182a:	89 fa                	mov    %edi,%edx
f010182c:	83 c4 1c             	add    $0x1c,%esp
f010182f:	5b                   	pop    %ebx
f0101830:	5e                   	pop    %esi
f0101831:	5f                   	pop    %edi
f0101832:	5d                   	pop    %ebp
f0101833:	c3                   	ret    
f0101834:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101838:	39 ce                	cmp    %ecx,%esi
f010183a:	72 0c                	jb     f0101848 <__udivdi3+0x118>
f010183c:	31 db                	xor    %ebx,%ebx
f010183e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101842:	0f 87 34 ff ff ff    	ja     f010177c <__udivdi3+0x4c>
f0101848:	bb 01 00 00 00       	mov    $0x1,%ebx
f010184d:	e9 2a ff ff ff       	jmp    f010177c <__udivdi3+0x4c>
f0101852:	66 90                	xchg   %ax,%ax
f0101854:	66 90                	xchg   %ax,%ax
f0101856:	66 90                	xchg   %ax,%ax
f0101858:	66 90                	xchg   %ax,%ax
f010185a:	66 90                	xchg   %ax,%ax
f010185c:	66 90                	xchg   %ax,%ax
f010185e:	66 90                	xchg   %ax,%ax

f0101860 <__umoddi3>:
f0101860:	55                   	push   %ebp
f0101861:	57                   	push   %edi
f0101862:	56                   	push   %esi
f0101863:	53                   	push   %ebx
f0101864:	83 ec 1c             	sub    $0x1c,%esp
f0101867:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010186b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010186f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101873:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101877:	85 d2                	test   %edx,%edx
f0101879:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010187d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101881:	89 f3                	mov    %esi,%ebx
f0101883:	89 3c 24             	mov    %edi,(%esp)
f0101886:	89 74 24 04          	mov    %esi,0x4(%esp)
f010188a:	75 1c                	jne    f01018a8 <__umoddi3+0x48>
f010188c:	39 f7                	cmp    %esi,%edi
f010188e:	76 50                	jbe    f01018e0 <__umoddi3+0x80>
f0101890:	89 c8                	mov    %ecx,%eax
f0101892:	89 f2                	mov    %esi,%edx
f0101894:	f7 f7                	div    %edi
f0101896:	89 d0                	mov    %edx,%eax
f0101898:	31 d2                	xor    %edx,%edx
f010189a:	83 c4 1c             	add    $0x1c,%esp
f010189d:	5b                   	pop    %ebx
f010189e:	5e                   	pop    %esi
f010189f:	5f                   	pop    %edi
f01018a0:	5d                   	pop    %ebp
f01018a1:	c3                   	ret    
f01018a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018a8:	39 f2                	cmp    %esi,%edx
f01018aa:	89 d0                	mov    %edx,%eax
f01018ac:	77 52                	ja     f0101900 <__umoddi3+0xa0>
f01018ae:	0f bd ea             	bsr    %edx,%ebp
f01018b1:	83 f5 1f             	xor    $0x1f,%ebp
f01018b4:	75 5a                	jne    f0101910 <__umoddi3+0xb0>
f01018b6:	3b 54 24 04          	cmp    0x4(%esp),%edx
f01018ba:	0f 82 e0 00 00 00    	jb     f01019a0 <__umoddi3+0x140>
f01018c0:	39 0c 24             	cmp    %ecx,(%esp)
f01018c3:	0f 86 d7 00 00 00    	jbe    f01019a0 <__umoddi3+0x140>
f01018c9:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018cd:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018d1:	83 c4 1c             	add    $0x1c,%esp
f01018d4:	5b                   	pop    %ebx
f01018d5:	5e                   	pop    %esi
f01018d6:	5f                   	pop    %edi
f01018d7:	5d                   	pop    %ebp
f01018d8:	c3                   	ret    
f01018d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01018e0:	85 ff                	test   %edi,%edi
f01018e2:	89 fd                	mov    %edi,%ebp
f01018e4:	75 0b                	jne    f01018f1 <__umoddi3+0x91>
f01018e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01018eb:	31 d2                	xor    %edx,%edx
f01018ed:	f7 f7                	div    %edi
f01018ef:	89 c5                	mov    %eax,%ebp
f01018f1:	89 f0                	mov    %esi,%eax
f01018f3:	31 d2                	xor    %edx,%edx
f01018f5:	f7 f5                	div    %ebp
f01018f7:	89 c8                	mov    %ecx,%eax
f01018f9:	f7 f5                	div    %ebp
f01018fb:	89 d0                	mov    %edx,%eax
f01018fd:	eb 99                	jmp    f0101898 <__umoddi3+0x38>
f01018ff:	90                   	nop
f0101900:	89 c8                	mov    %ecx,%eax
f0101902:	89 f2                	mov    %esi,%edx
f0101904:	83 c4 1c             	add    $0x1c,%esp
f0101907:	5b                   	pop    %ebx
f0101908:	5e                   	pop    %esi
f0101909:	5f                   	pop    %edi
f010190a:	5d                   	pop    %ebp
f010190b:	c3                   	ret    
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	8b 34 24             	mov    (%esp),%esi
f0101913:	bf 20 00 00 00       	mov    $0x20,%edi
f0101918:	89 e9                	mov    %ebp,%ecx
f010191a:	29 ef                	sub    %ebp,%edi
f010191c:	d3 e0                	shl    %cl,%eax
f010191e:	89 f9                	mov    %edi,%ecx
f0101920:	89 f2                	mov    %esi,%edx
f0101922:	d3 ea                	shr    %cl,%edx
f0101924:	89 e9                	mov    %ebp,%ecx
f0101926:	09 c2                	or     %eax,%edx
f0101928:	89 d8                	mov    %ebx,%eax
f010192a:	89 14 24             	mov    %edx,(%esp)
f010192d:	89 f2                	mov    %esi,%edx
f010192f:	d3 e2                	shl    %cl,%edx
f0101931:	89 f9                	mov    %edi,%ecx
f0101933:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101937:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010193b:	d3 e8                	shr    %cl,%eax
f010193d:	89 e9                	mov    %ebp,%ecx
f010193f:	89 c6                	mov    %eax,%esi
f0101941:	d3 e3                	shl    %cl,%ebx
f0101943:	89 f9                	mov    %edi,%ecx
f0101945:	89 d0                	mov    %edx,%eax
f0101947:	d3 e8                	shr    %cl,%eax
f0101949:	89 e9                	mov    %ebp,%ecx
f010194b:	09 d8                	or     %ebx,%eax
f010194d:	89 d3                	mov    %edx,%ebx
f010194f:	89 f2                	mov    %esi,%edx
f0101951:	f7 34 24             	divl   (%esp)
f0101954:	89 d6                	mov    %edx,%esi
f0101956:	d3 e3                	shl    %cl,%ebx
f0101958:	f7 64 24 04          	mull   0x4(%esp)
f010195c:	39 d6                	cmp    %edx,%esi
f010195e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101962:	89 d1                	mov    %edx,%ecx
f0101964:	89 c3                	mov    %eax,%ebx
f0101966:	72 08                	jb     f0101970 <__umoddi3+0x110>
f0101968:	75 11                	jne    f010197b <__umoddi3+0x11b>
f010196a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010196e:	73 0b                	jae    f010197b <__umoddi3+0x11b>
f0101970:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101974:	1b 14 24             	sbb    (%esp),%edx
f0101977:	89 d1                	mov    %edx,%ecx
f0101979:	89 c3                	mov    %eax,%ebx
f010197b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010197f:	29 da                	sub    %ebx,%edx
f0101981:	19 ce                	sbb    %ecx,%esi
f0101983:	89 f9                	mov    %edi,%ecx
f0101985:	89 f0                	mov    %esi,%eax
f0101987:	d3 e0                	shl    %cl,%eax
f0101989:	89 e9                	mov    %ebp,%ecx
f010198b:	d3 ea                	shr    %cl,%edx
f010198d:	89 e9                	mov    %ebp,%ecx
f010198f:	d3 ee                	shr    %cl,%esi
f0101991:	09 d0                	or     %edx,%eax
f0101993:	89 f2                	mov    %esi,%edx
f0101995:	83 c4 1c             	add    $0x1c,%esp
f0101998:	5b                   	pop    %ebx
f0101999:	5e                   	pop    %esi
f010199a:	5f                   	pop    %edi
f010199b:	5d                   	pop    %ebp
f010199c:	c3                   	ret    
f010199d:	8d 76 00             	lea    0x0(%esi),%esi
f01019a0:	29 f9                	sub    %edi,%ecx
f01019a2:	19 d6                	sbb    %edx,%esi
f01019a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019a8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019ac:	e9 18 ff ff ff       	jmp    f01018c9 <__umoddi3+0x69>
