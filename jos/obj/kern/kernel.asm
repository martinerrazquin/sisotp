
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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 a0 11 00       	mov    $0x11a000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	movl	%cr4,%eax
f010001d:	0f 20 e0             	mov    %cr4,%eax
	orl		$(CR4_PSE),%eax	#Prendo flag del cr4 para Page Size Extension
f0100020:	83 c8 10             	or     $0x10,%eax
	movl	%eax,%cr4	
f0100023:	0f 22 e0             	mov    %eax,%cr4
	# Turn on paging.
	movl	%cr0, %eax
f0100026:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100029:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f010002e:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100031:	b8 38 00 10 f0       	mov    $0xf0100038,%eax
	jmp	*%eax
f0100036:	ff e0                	jmp    *%eax

f0100038 <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f0100038:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f010003d:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100042:	e8 09 00 00 00       	call   f0100050 <i386_init>

f0100047 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100047:	eb fe                	jmp    f0100047 <spin>
f0100049:	66 90                	xchg   %ax,%ax
f010004b:	66 90                	xchg   %ax,%ax
f010004d:	66 90                	xchg   %ax,%ax
f010004f:	90                   	nop

f0100050 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100050:	55                   	push   %ebp
f0100051:	89 e5                	mov    %esp,%ebp
f0100053:	83 ec 18             	sub    $0x18,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f0100056:	b8 90 6f 18 f0       	mov    $0xf0186f90,%eax
f010005b:	2d 80 50 18 f0       	sub    $0xf0185080,%eax
f0100060:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100064:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010006b:	00 
f010006c:	c7 04 24 80 50 18 f0 	movl   $0xf0185080,(%esp)
f0100073:	e8 af 47 00 00       	call   f0104827 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100078:	e8 a4 06 00 00       	call   f0100721 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010007d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100084:	00 
f0100085:	c7 04 24 c0 4c 10 f0 	movl   $0xf0104cc0,(%esp)
f010008c:	e8 d1 37 00 00       	call   f0103862 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100091:	e8 71 2b 00 00       	call   f0102c07 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100096:	e8 72 33 00 00       	call   f010340d <env_init>
	trap_init();
f010009b:	90                   	nop
f010009c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01000a0:	e8 7a 38 00 00       	call   f010391f <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f01000a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000ac:	00 
f01000ad:	c7 04 24 56 b3 11 f0 	movl   $0xf011b356,(%esp)
f01000b4:	e8 8a 34 00 00       	call   f0103543 <env_create>
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b9:	a1 c8 52 18 f0       	mov    0xf01852c8,%eax
f01000be:	89 04 24             	mov    %eax,(%esp)
f01000c1:	e8 7c 36 00 00       	call   f0103742 <env_run>

f01000c6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000c6:	55                   	push   %ebp
f01000c7:	89 e5                	mov    %esp,%ebp
f01000c9:	56                   	push   %esi
f01000ca:	53                   	push   %ebx
f01000cb:	83 ec 10             	sub    $0x10,%esp
f01000ce:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000d1:	83 3d 80 6f 18 f0 00 	cmpl   $0x0,0xf0186f80
f01000d8:	75 3d                	jne    f0100117 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000da:	89 35 80 6f 18 f0    	mov    %esi,0xf0186f80

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000e0:	fa                   	cli    
f01000e1:	fc                   	cld    

	va_start(ap, fmt);
f01000e2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000e8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01000ef:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000f3:	c7 04 24 fc 4c 10 f0 	movl   $0xf0104cfc,(%esp)
f01000fa:	e8 63 37 00 00       	call   f0103862 <cprintf>
	vcprintf(fmt, ap);
f01000ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100103:	89 34 24             	mov    %esi,(%esp)
f0100106:	e8 24 37 00 00       	call   f010382f <vcprintf>
	cprintf("\n>>>\n");
f010010b:	c7 04 24 db 4c 10 f0 	movl   $0xf0104cdb,(%esp)
f0100112:	e8 4b 37 00 00       	call   f0103862 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100117:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010011e:	e8 31 09 00 00       	call   f0100a54 <monitor>
f0100123:	eb f2                	jmp    f0100117 <_panic+0x51>

f0100125 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100125:	55                   	push   %ebp
f0100126:	89 e5                	mov    %esp,%ebp
f0100128:	53                   	push   %ebx
f0100129:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010012c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010012f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100132:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100136:	8b 45 08             	mov    0x8(%ebp),%eax
f0100139:	89 44 24 04          	mov    %eax,0x4(%esp)
f010013d:	c7 04 24 e1 4c 10 f0 	movl   $0xf0104ce1,(%esp)
f0100144:	e8 19 37 00 00       	call   f0103862 <cprintf>
	vcprintf(fmt, ap);
f0100149:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010014d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100150:	89 04 24             	mov    %eax,(%esp)
f0100153:	e8 d7 36 00 00       	call   f010382f <vcprintf>
	cprintf("\n");
f0100158:	c7 04 24 2a 5d 10 f0 	movl   $0xf0105d2a,(%esp)
f010015f:	e8 fe 36 00 00       	call   f0103862 <cprintf>
	va_end(ap);
}
f0100164:	83 c4 14             	add    $0x14,%esp
f0100167:	5b                   	pop    %ebx
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    
f010016a:	66 90                	xchg   %ax,%ax
f010016c:	66 90                	xchg   %ax,%ax
f010016e:	66 90                	xchg   %ax,%ax

f0100170 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100173:	89 c2                	mov    %eax,%edx
f0100175:	ec                   	in     (%dx),%al
	return data;
}
f0100176:	5d                   	pop    %ebp
f0100177:	c3                   	ret    

f0100178 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100178:	55                   	push   %ebp
f0100179:	89 e5                	mov    %esp,%ebp
f010017b:	89 c1                	mov    %eax,%ecx
f010017d:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010017f:	89 ca                	mov    %ecx,%edx
f0100181:	ee                   	out    %al,(%dx)
}
f0100182:	5d                   	pop    %ebp
f0100183:	c3                   	ret    

f0100184 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100184:	55                   	push   %ebp
f0100185:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100187:	b8 84 00 00 00       	mov    $0x84,%eax
f010018c:	e8 df ff ff ff       	call   f0100170 <inb>
	inb(0x84);
f0100191:	b8 84 00 00 00       	mov    $0x84,%eax
f0100196:	e8 d5 ff ff ff       	call   f0100170 <inb>
	inb(0x84);
f010019b:	b8 84 00 00 00       	mov    $0x84,%eax
f01001a0:	e8 cb ff ff ff       	call   f0100170 <inb>
	inb(0x84);
f01001a5:	b8 84 00 00 00       	mov    $0x84,%eax
f01001aa:	e8 c1 ff ff ff       	call   f0100170 <inb>
}
f01001af:	5d                   	pop    %ebp
f01001b0:	c3                   	ret    

f01001b1 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001b1:	55                   	push   %ebp
f01001b2:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b4:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001b9:	e8 b2 ff ff ff       	call   f0100170 <inb>
f01001be:	a8 01                	test   $0x1,%al
f01001c0:	74 0f                	je     f01001d1 <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f01001c2:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001c7:	e8 a4 ff ff ff       	call   f0100170 <inb>
f01001cc:	0f b6 c0             	movzbl %al,%eax
f01001cf:	eb 05                	jmp    f01001d6 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001d6:	5d                   	pop    %ebp
f01001d7:	c3                   	ret    

f01001d8 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f01001d8:	55                   	push   %ebp
f01001d9:	89 e5                	mov    %esp,%ebp
f01001db:	56                   	push   %esi
f01001dc:	53                   	push   %ebx
f01001dd:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f01001df:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001e4:	eb 05                	jmp    f01001eb <serial_putc+0x13>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001e6:	e8 99 ff ff ff       	call   f0100184 <delay>
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001eb:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001f0:	e8 7b ff ff ff       	call   f0100170 <inb>
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001f5:	a8 20                	test   $0x20,%al
f01001f7:	75 05                	jne    f01001fe <serial_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001f9:	83 eb 01             	sub    $0x1,%ebx
f01001fc:	75 e8                	jne    f01001e6 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001fe:	89 f0                	mov    %esi,%eax
f0100200:	0f b6 d0             	movzbl %al,%edx
f0100203:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100208:	e8 6b ff ff ff       	call   f0100178 <outb>
}
f010020d:	5b                   	pop    %ebx
f010020e:	5e                   	pop    %esi
f010020f:	5d                   	pop    %ebp
f0100210:	c3                   	ret    

f0100211 <serial_init>:

static void
serial_init(void)
{
f0100211:	55                   	push   %ebp
f0100212:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f0100214:	ba 00 00 00 00       	mov    $0x0,%edx
f0100219:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f010021e:	e8 55 ff ff ff       	call   f0100178 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f0100223:	ba 80 00 00 00       	mov    $0x80,%edx
f0100228:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010022d:	e8 46 ff ff ff       	call   f0100178 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f0100232:	ba 0c 00 00 00       	mov    $0xc,%edx
f0100237:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010023c:	e8 37 ff ff ff       	call   f0100178 <outb>
	outb(COM1+COM_DLM, 0);
f0100241:	ba 00 00 00 00       	mov    $0x0,%edx
f0100246:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010024b:	e8 28 ff ff ff       	call   f0100178 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100250:	ba 03 00 00 00       	mov    $0x3,%edx
f0100255:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010025a:	e8 19 ff ff ff       	call   f0100178 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010025f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100264:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100269:	e8 0a ff ff ff       	call   f0100178 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f010026e:	ba 01 00 00 00       	mov    $0x1,%edx
f0100273:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100278:	e8 fb fe ff ff       	call   f0100178 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010027d:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100282:	e8 e9 fe ff ff       	call   f0100170 <inb>
f0100287:	3c ff                	cmp    $0xff,%al
f0100289:	0f 95 05 b4 52 18 f0 	setne  0xf01852b4
	(void) inb(COM1+COM_IIR);
f0100290:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100295:	e8 d6 fe ff ff       	call   f0100170 <inb>
	(void) inb(COM1+COM_RX);
f010029a:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010029f:	e8 cc fe ff ff       	call   f0100170 <inb>

}
f01002a4:	5d                   	pop    %ebp
f01002a5:	c3                   	ret    

f01002a6 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f01002a6:	55                   	push   %ebp
f01002a7:	89 e5                	mov    %esp,%ebp
f01002a9:	56                   	push   %esi
f01002aa:	53                   	push   %ebx
f01002ab:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002ad:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01002b2:	eb 05                	jmp    f01002b9 <lpt_putc+0x13>
		delay();
f01002b4:	e8 cb fe ff ff       	call   f0100184 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002b9:	b8 79 03 00 00       	mov    $0x379,%eax
f01002be:	e8 ad fe ff ff       	call   f0100170 <inb>
f01002c3:	84 c0                	test   %al,%al
f01002c5:	78 05                	js     f01002cc <lpt_putc+0x26>
f01002c7:	83 eb 01             	sub    $0x1,%ebx
f01002ca:	75 e8                	jne    f01002b4 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f01002cc:	89 f0                	mov    %esi,%eax
f01002ce:	0f b6 d0             	movzbl %al,%edx
f01002d1:	b8 78 03 00 00       	mov    $0x378,%eax
f01002d6:	e8 9d fe ff ff       	call   f0100178 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f01002db:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002e0:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002e5:	e8 8e fe ff ff       	call   f0100178 <outb>
	outb(0x378+2, 0x08);
f01002ea:	ba 08 00 00 00       	mov    $0x8,%edx
f01002ef:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002f4:	e8 7f fe ff ff       	call   f0100178 <outb>
}
f01002f9:	5b                   	pop    %ebx
f01002fa:	5e                   	pop    %esi
f01002fb:	5d                   	pop    %ebp
f01002fc:	c3                   	ret    

f01002fd <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002fd:	55                   	push   %ebp
f01002fe:	89 e5                	mov    %esp,%ebp
f0100300:	57                   	push   %edi
f0100301:	56                   	push   %esi
f0100302:	53                   	push   %ebx
f0100303:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100306:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010030d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100314:	5a a5 
	if (*cp != 0xA55A) {
f0100316:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010031d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100321:	74 11                	je     f0100334 <cga_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100323:	c7 05 b0 52 18 f0 b4 	movl   $0x3b4,0xf01852b0
f010032a:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010032d:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100332:	eb 16                	jmp    f010034a <cga_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100334:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010033b:	c7 05 b0 52 18 f0 d4 	movl   $0x3d4,0xf01852b0
f0100342:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100345:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010034a:	8b 1d b0 52 18 f0    	mov    0xf01852b0,%ebx
f0100350:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100355:	89 d8                	mov    %ebx,%eax
f0100357:	e8 1c fe ff ff       	call   f0100178 <outb>
	pos = inb(addr_6845 + 1) << 8;
f010035c:	8d 73 01             	lea    0x1(%ebx),%esi
f010035f:	89 f0                	mov    %esi,%eax
f0100361:	e8 0a fe ff ff       	call   f0100170 <inb>
f0100366:	0f b6 c0             	movzbl %al,%eax
f0100369:	c1 e0 08             	shl    $0x8,%eax
f010036c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f010036f:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100374:	89 d8                	mov    %ebx,%eax
f0100376:	e8 fd fd ff ff       	call   f0100178 <outb>
	pos |= inb(addr_6845 + 1);
f010037b:	89 f0                	mov    %esi,%eax
f010037d:	e8 ee fd ff ff       	call   f0100170 <inb>

	crt_buf = (uint16_t*) cp;
f0100382:	89 3d ac 52 18 f0    	mov    %edi,0xf01852ac

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100388:	0f b6 c0             	movzbl %al,%eax
f010038b:	0b 45 f0             	or     -0x10(%ebp),%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010038e:	66 a3 a8 52 18 f0    	mov    %ax,0xf01852a8
}
f0100394:	83 c4 04             	add    $0x4,%esp
f0100397:	5b                   	pop    %ebx
f0100398:	5e                   	pop    %esi
f0100399:	5f                   	pop    %edi
f010039a:	5d                   	pop    %ebp
f010039b:	c3                   	ret    

f010039c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010039c:	55                   	push   %ebp
f010039d:	89 e5                	mov    %esp,%ebp
f010039f:	53                   	push   %ebx
f01003a0:	83 ec 04             	sub    $0x4,%esp
f01003a3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01003a5:	eb 2a                	jmp    f01003d1 <cons_intr+0x35>
		if (c == 0)
f01003a7:	85 d2                	test   %edx,%edx
f01003a9:	74 26                	je     f01003d1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01003ab:	a1 a4 52 18 f0       	mov    0xf01852a4,%eax
f01003b0:	8d 48 01             	lea    0x1(%eax),%ecx
f01003b3:	89 0d a4 52 18 f0    	mov    %ecx,0xf01852a4
f01003b9:	88 90 a0 50 18 f0    	mov    %dl,-0xfe7af60(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01003bf:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01003c5:	75 0a                	jne    f01003d1 <cons_intr+0x35>
			cons.wpos = 0;
f01003c7:	c7 05 a4 52 18 f0 00 	movl   $0x0,0xf01852a4
f01003ce:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003d1:	ff d3                	call   *%ebx
f01003d3:	89 c2                	mov    %eax,%edx
f01003d5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003d8:	75 cd                	jne    f01003a7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003da:	83 c4 04             	add    $0x4,%esp
f01003dd:	5b                   	pop    %ebx
f01003de:	5d                   	pop    %ebp
f01003df:	c3                   	ret    

f01003e0 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003e0:	55                   	push   %ebp
f01003e1:	89 e5                	mov    %esp,%ebp
f01003e3:	53                   	push   %ebx
f01003e4:	83 ec 14             	sub    $0x14,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003e7:	b8 64 00 00 00       	mov    $0x64,%eax
f01003ec:	e8 7f fd ff ff       	call   f0100170 <inb>
	if ((stat & KBS_DIB) == 0)
f01003f1:	a8 01                	test   $0x1,%al
f01003f3:	0f 84 fd 00 00 00    	je     f01004f6 <kbd_proc_data+0x116>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003f9:	a8 20                	test   $0x20,%al
f01003fb:	0f 85 fc 00 00 00    	jne    f01004fd <kbd_proc_data+0x11d>
		return -1;

	data = inb(KBDATAP);
f0100401:	b8 60 00 00 00       	mov    $0x60,%eax
f0100406:	e8 65 fd ff ff       	call   f0100170 <inb>

	if (data == 0xE0) {
f010040b:	3c e0                	cmp    $0xe0,%al
f010040d:	75 11                	jne    f0100420 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f010040f:	83 0d 80 50 18 f0 40 	orl    $0x40,0xf0185080
		return 0;
f0100416:	b8 00 00 00 00       	mov    $0x0,%eax
f010041b:	e9 e2 00 00 00       	jmp    f0100502 <kbd_proc_data+0x122>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 39                	jns    f010045d <kbd_proc_data+0x7d>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 15 80 50 18 f0    	mov    0xf0185080,%edx
f010042a:	89 d3                	mov    %edx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	89 c1                	mov    %eax,%ecx
f0100431:	83 e1 7f             	and    $0x7f,%ecx
f0100434:	85 db                	test   %ebx,%ebx
f0100436:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100439:	0f b6 c0             	movzbl %al,%eax
f010043c:	0f b6 80 80 4e 10 f0 	movzbl -0xfefb180(%eax),%eax
f0100443:	83 c8 40             	or     $0x40,%eax
f0100446:	0f b6 c0             	movzbl %al,%eax
f0100449:	f7 d0                	not    %eax
f010044b:	21 c2                	and    %eax,%edx
f010044d:	89 15 80 50 18 f0    	mov    %edx,0xf0185080
		return 0;
f0100453:	b8 00 00 00 00       	mov    $0x0,%eax
f0100458:	e9 a5 00 00 00       	jmp    f0100502 <kbd_proc_data+0x122>
	} else if (shift & E0ESC) {
f010045d:	8b 15 80 50 18 f0    	mov    0xf0185080,%edx
f0100463:	f6 c2 40             	test   $0x40,%dl
f0100466:	74 0c                	je     f0100474 <kbd_proc_data+0x94>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100468:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f010046b:	83 e2 bf             	and    $0xffffffbf,%edx
f010046e:	89 15 80 50 18 f0    	mov    %edx,0xf0185080
	}

	shift |= shiftcode[data];
f0100474:	0f b6 c0             	movzbl %al,%eax
f0100477:	0f b6 90 80 4e 10 f0 	movzbl -0xfefb180(%eax),%edx
f010047e:	0b 15 80 50 18 f0    	or     0xf0185080,%edx
	shift ^= togglecode[data];
f0100484:	0f b6 88 80 4d 10 f0 	movzbl -0xfefb280(%eax),%ecx
f010048b:	31 ca                	xor    %ecx,%edx
f010048d:	89 15 80 50 18 f0    	mov    %edx,0xf0185080

	c = charcode[shift & (CTL | SHIFT)][data];
f0100493:	89 d1                	mov    %edx,%ecx
f0100495:	83 e1 03             	and    $0x3,%ecx
f0100498:	8b 0c 8d 60 4d 10 f0 	mov    -0xfefb2a0(,%ecx,4),%ecx
f010049f:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f01004a3:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f01004a6:	f6 c2 08             	test   $0x8,%dl
f01004a9:	74 1b                	je     f01004c6 <kbd_proc_data+0xe6>
		if ('a' <= c && c <= 'z')
f01004ab:	89 d8                	mov    %ebx,%eax
f01004ad:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004b0:	83 f9 19             	cmp    $0x19,%ecx
f01004b3:	77 05                	ja     f01004ba <kbd_proc_data+0xda>
			c += 'A' - 'a';
f01004b5:	83 eb 20             	sub    $0x20,%ebx
f01004b8:	eb 0c                	jmp    f01004c6 <kbd_proc_data+0xe6>
		else if ('A' <= c && c <= 'Z')
f01004ba:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f01004bd:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004c0:	83 f8 19             	cmp    $0x19,%eax
f01004c3:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004c6:	f7 d2                	not    %edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004c8:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004ca:	f6 c2 06             	test   $0x6,%dl
f01004cd:	75 33                	jne    f0100502 <kbd_proc_data+0x122>
f01004cf:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004d5:	75 2b                	jne    f0100502 <kbd_proc_data+0x122>
		cprintf("Rebooting!\n");
f01004d7:	c7 04 24 1c 4d 10 f0 	movl   $0xf0104d1c,(%esp)
f01004de:	e8 7f 33 00 00       	call   f0103862 <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004e3:	ba 03 00 00 00       	mov    $0x3,%edx
f01004e8:	b8 92 00 00 00       	mov    $0x92,%eax
f01004ed:	e8 86 fc ff ff       	call   f0100178 <outb>
	}

	return c;
f01004f2:	89 d8                	mov    %ebx,%eax
f01004f4:	eb 0c                	jmp    f0100502 <kbd_proc_data+0x122>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004fb:	eb 05                	jmp    f0100502 <kbd_proc_data+0x122>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100502:	83 c4 14             	add    $0x14,%esp
f0100505:	5b                   	pop    %ebx
f0100506:	5d                   	pop    %ebp
f0100507:	c3                   	ret    

f0100508 <cga_putc>:



static void
cga_putc(int c)
{
f0100508:	55                   	push   %ebp
f0100509:	89 e5                	mov    %esp,%ebp
f010050b:	57                   	push   %edi
f010050c:	56                   	push   %esi
f010050d:	53                   	push   %ebx
f010050e:	83 ec 1c             	sub    $0x1c,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100511:	89 c1                	mov    %eax,%ecx
f0100513:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f0100519:	89 c2                	mov    %eax,%edx
f010051b:	80 ce 07             	or     $0x7,%dh
f010051e:	85 c9                	test   %ecx,%ecx
f0100520:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100523:	0f b6 d0             	movzbl %al,%edx
f0100526:	83 fa 09             	cmp    $0x9,%edx
f0100529:	74 75                	je     f01005a0 <cga_putc+0x98>
f010052b:	83 fa 09             	cmp    $0x9,%edx
f010052e:	7f 0a                	jg     f010053a <cga_putc+0x32>
f0100530:	83 fa 08             	cmp    $0x8,%edx
f0100533:	74 17                	je     f010054c <cga_putc+0x44>
f0100535:	e9 9a 00 00 00       	jmp    f01005d4 <cga_putc+0xcc>
f010053a:	83 fa 0a             	cmp    $0xa,%edx
f010053d:	8d 76 00             	lea    0x0(%esi),%esi
f0100540:	74 38                	je     f010057a <cga_putc+0x72>
f0100542:	83 fa 0d             	cmp    $0xd,%edx
f0100545:	74 3b                	je     f0100582 <cga_putc+0x7a>
f0100547:	e9 88 00 00 00       	jmp    f01005d4 <cga_putc+0xcc>
	case '\b':
		if (crt_pos > 0) {
f010054c:	0f b7 15 a8 52 18 f0 	movzwl 0xf01852a8,%edx
f0100553:	66 85 d2             	test   %dx,%dx
f0100556:	0f 84 e3 00 00 00    	je     f010063f <cga_putc+0x137>
			crt_pos--;
f010055c:	83 ea 01             	sub    $0x1,%edx
f010055f:	66 89 15 a8 52 18 f0 	mov    %dx,0xf01852a8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100566:	0f b7 d2             	movzwl %dx,%edx
f0100569:	b0 00                	mov    $0x0,%al
f010056b:	83 c8 20             	or     $0x20,%eax
f010056e:	8b 0d ac 52 18 f0    	mov    0xf01852ac,%ecx
f0100574:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100578:	eb 78                	jmp    f01005f2 <cga_putc+0xea>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010057a:	66 83 05 a8 52 18 f0 	addw   $0x50,0xf01852a8
f0100581:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100582:	0f b7 05 a8 52 18 f0 	movzwl 0xf01852a8,%eax
f0100589:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010058f:	c1 e8 16             	shr    $0x16,%eax
f0100592:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100595:	c1 e0 04             	shl    $0x4,%eax
f0100598:	66 a3 a8 52 18 f0    	mov    %ax,0xf01852a8
		break;
f010059e:	eb 52                	jmp    f01005f2 <cga_putc+0xea>
	case '\t':
		cons_putc(' ');
f01005a0:	b8 20 00 00 00       	mov    $0x20,%eax
f01005a5:	e8 dd 00 00 00       	call   f0100687 <cons_putc>
		cons_putc(' ');
f01005aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01005af:	e8 d3 00 00 00       	call   f0100687 <cons_putc>
		cons_putc(' ');
f01005b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01005b9:	e8 c9 00 00 00       	call   f0100687 <cons_putc>
		cons_putc(' ');
f01005be:	b8 20 00 00 00       	mov    $0x20,%eax
f01005c3:	e8 bf 00 00 00       	call   f0100687 <cons_putc>
		cons_putc(' ');
f01005c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01005cd:	e8 b5 00 00 00       	call   f0100687 <cons_putc>
		break;
f01005d2:	eb 1e                	jmp    f01005f2 <cga_putc+0xea>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005d4:	0f b7 15 a8 52 18 f0 	movzwl 0xf01852a8,%edx
f01005db:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005de:	66 89 0d a8 52 18 f0 	mov    %cx,0xf01852a8
f01005e5:	0f b7 d2             	movzwl %dx,%edx
f01005e8:	8b 0d ac 52 18 f0    	mov    0xf01852ac,%ecx
f01005ee:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005f2:	66 81 3d a8 52 18 f0 	cmpw   $0x7cf,0xf01852a8
f01005f9:	cf 07 
f01005fb:	76 42                	jbe    f010063f <cga_putc+0x137>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005fd:	a1 ac 52 18 f0       	mov    0xf01852ac,%eax
f0100602:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100609:	00 
f010060a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100610:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100614:	89 04 24             	mov    %eax,(%esp)
f0100617:	e8 59 42 00 00       	call   f0104875 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010061c:	8b 15 ac 52 18 f0    	mov    0xf01852ac,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100622:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100627:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010062d:	83 c0 01             	add    $0x1,%eax
f0100630:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100635:	75 f0                	jne    f0100627 <cga_putc+0x11f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100637:	66 83 2d a8 52 18 f0 	subw   $0x50,0xf01852a8
f010063e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010063f:	8b 1d b0 52 18 f0    	mov    0xf01852b0,%ebx
f0100645:	ba 0e 00 00 00       	mov    $0xe,%edx
f010064a:	89 d8                	mov    %ebx,%eax
f010064c:	e8 27 fb ff ff       	call   f0100178 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100651:	0f b7 3d a8 52 18 f0 	movzwl 0xf01852a8,%edi
f0100658:	8d 73 01             	lea    0x1(%ebx),%esi
f010065b:	89 f8                	mov    %edi,%eax
f010065d:	0f b6 d4             	movzbl %ah,%edx
f0100660:	89 f0                	mov    %esi,%eax
f0100662:	e8 11 fb ff ff       	call   f0100178 <outb>
	outb(addr_6845, 15);
f0100667:	ba 0f 00 00 00       	mov    $0xf,%edx
f010066c:	89 d8                	mov    %ebx,%eax
f010066e:	e8 05 fb ff ff       	call   f0100178 <outb>
	outb(addr_6845 + 1, crt_pos);
f0100673:	89 f8                	mov    %edi,%eax
f0100675:	0f b6 d0             	movzbl %al,%edx
f0100678:	89 f0                	mov    %esi,%eax
f010067a:	e8 f9 fa ff ff       	call   f0100178 <outb>
}
f010067f:	83 c4 1c             	add    $0x1c,%esp
f0100682:	5b                   	pop    %ebx
f0100683:	5e                   	pop    %esi
f0100684:	5f                   	pop    %edi
f0100685:	5d                   	pop    %ebp
f0100686:	c3                   	ret    

f0100687 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100687:	55                   	push   %ebp
f0100688:	89 e5                	mov    %esp,%ebp
f010068a:	53                   	push   %ebx
f010068b:	83 ec 04             	sub    $0x4,%esp
f010068e:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100690:	e8 43 fb ff ff       	call   f01001d8 <serial_putc>
	lpt_putc(c);
f0100695:	89 d8                	mov    %ebx,%eax
f0100697:	e8 0a fc ff ff       	call   f01002a6 <lpt_putc>
	cga_putc(c);
f010069c:	89 d8                	mov    %ebx,%eax
f010069e:	e8 65 fe ff ff       	call   f0100508 <cga_putc>
}
f01006a3:	83 c4 04             	add    $0x4,%esp
f01006a6:	5b                   	pop    %ebx
f01006a7:	5d                   	pop    %ebp
f01006a8:	c3                   	ret    

f01006a9 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01006a9:	80 3d b4 52 18 f0 00 	cmpb   $0x0,0xf01852b4
f01006b0:	74 11                	je     f01006c3 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01006b2:	55                   	push   %ebp
f01006b3:	89 e5                	mov    %esp,%ebp
f01006b5:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01006b8:	b8 b1 01 10 f0       	mov    $0xf01001b1,%eax
f01006bd:	e8 da fc ff ff       	call   f010039c <cons_intr>
}
f01006c2:	c9                   	leave  
f01006c3:	f3 c3                	repz ret 

f01006c5 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01006c5:	55                   	push   %ebp
f01006c6:	89 e5                	mov    %esp,%ebp
f01006c8:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006cb:	b8 e0 03 10 f0       	mov    $0xf01003e0,%eax
f01006d0:	e8 c7 fc ff ff       	call   f010039c <cons_intr>
}
f01006d5:	c9                   	leave  
f01006d6:	c3                   	ret    

f01006d7 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01006d7:	55                   	push   %ebp
f01006d8:	89 e5                	mov    %esp,%ebp
f01006da:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01006dd:	e8 c7 ff ff ff       	call   f01006a9 <serial_intr>
	kbd_intr();
f01006e2:	e8 de ff ff ff       	call   f01006c5 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006e7:	a1 a0 52 18 f0       	mov    0xf01852a0,%eax
f01006ec:	3b 05 a4 52 18 f0    	cmp    0xf01852a4,%eax
f01006f2:	74 26                	je     f010071a <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006f4:	8d 50 01             	lea    0x1(%eax),%edx
f01006f7:	89 15 a0 52 18 f0    	mov    %edx,0xf01852a0
f01006fd:	0f b6 88 a0 50 18 f0 	movzbl -0xfe7af60(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100704:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100706:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010070c:	75 11                	jne    f010071f <cons_getc+0x48>
			cons.rpos = 0;
f010070e:	c7 05 a0 52 18 f0 00 	movl   $0x0,0xf01852a0
f0100715:	00 00 00 
f0100718:	eb 05                	jmp    f010071f <cons_getc+0x48>
		return c;
	}
	return 0;
f010071a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010071f:	c9                   	leave  
f0100720:	c3                   	ret    

f0100721 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100721:	55                   	push   %ebp
f0100722:	89 e5                	mov    %esp,%ebp
f0100724:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f0100727:	e8 d1 fb ff ff       	call   f01002fd <cga_init>
	kbd_init();
	serial_init();
f010072c:	e8 e0 fa ff ff       	call   f0100211 <serial_init>

	if (!serial_exists)
f0100731:	80 3d b4 52 18 f0 00 	cmpb   $0x0,0xf01852b4
f0100738:	75 0c                	jne    f0100746 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f010073a:	c7 04 24 28 4d 10 f0 	movl   $0xf0104d28,(%esp)
f0100741:	e8 1c 31 00 00       	call   f0103862 <cprintf>
}
f0100746:	c9                   	leave  
f0100747:	c3                   	ret    

f0100748 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100748:	55                   	push   %ebp
f0100749:	89 e5                	mov    %esp,%ebp
f010074b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010074e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100751:	e8 31 ff ff ff       	call   f0100687 <cons_putc>
}
f0100756:	c9                   	leave  
f0100757:	c3                   	ret    

f0100758 <getchar>:

int
getchar(void)
{
f0100758:	55                   	push   %ebp
f0100759:	89 e5                	mov    %esp,%ebp
f010075b:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010075e:	e8 74 ff ff ff       	call   f01006d7 <cons_getc>
f0100763:	85 c0                	test   %eax,%eax
f0100765:	74 f7                	je     f010075e <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100767:	c9                   	leave  
f0100768:	c3                   	ret    

f0100769 <iscons>:

int
iscons(int fdnum)
{
f0100769:	55                   	push   %ebp
f010076a:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010076c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100771:	5d                   	pop    %ebp
f0100772:	c3                   	ret    
f0100773:	66 90                	xchg   %ax,%ax
f0100775:	66 90                	xchg   %ax,%ax
f0100777:	66 90                	xchg   %ax,%ax
f0100779:	66 90                	xchg   %ax,%ax
f010077b:	66 90                	xchg   %ax,%ax
f010077d:	66 90                	xchg   %ax,%ax
f010077f:	90                   	nop

f0100780 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100780:	55                   	push   %ebp
f0100781:	89 e5                	mov    %esp,%ebp
f0100783:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100786:	c7 44 24 08 80 4f 10 	movl   $0xf0104f80,0x8(%esp)
f010078d:	f0 
f010078e:	c7 44 24 04 9e 4f 10 	movl   $0xf0104f9e,0x4(%esp)
f0100795:	f0 
f0100796:	c7 04 24 a3 4f 10 f0 	movl   $0xf0104fa3,(%esp)
f010079d:	e8 c0 30 00 00       	call   f0103862 <cprintf>
f01007a2:	c7 44 24 08 40 50 10 	movl   $0xf0105040,0x8(%esp)
f01007a9:	f0 
f01007aa:	c7 44 24 04 ac 4f 10 	movl   $0xf0104fac,0x4(%esp)
f01007b1:	f0 
f01007b2:	c7 04 24 a3 4f 10 f0 	movl   $0xf0104fa3,(%esp)
f01007b9:	e8 a4 30 00 00       	call   f0103862 <cprintf>
f01007be:	c7 44 24 08 b5 4f 10 	movl   $0xf0104fb5,0x8(%esp)
f01007c5:	f0 
f01007c6:	c7 44 24 04 c9 4f 10 	movl   $0xf0104fc9,0x4(%esp)
f01007cd:	f0 
f01007ce:	c7 04 24 a3 4f 10 f0 	movl   $0xf0104fa3,(%esp)
f01007d5:	e8 88 30 00 00       	call   f0103862 <cprintf>
	return 0;
}
f01007da:	b8 00 00 00 00       	mov    $0x0,%eax
f01007df:	c9                   	leave  
f01007e0:	c3                   	ret    

f01007e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007e1:	55                   	push   %ebp
f01007e2:	89 e5                	mov    %esp,%ebp
f01007e4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007e7:	c7 04 24 d3 4f 10 f0 	movl   $0xf0104fd3,(%esp)
f01007ee:	e8 6f 30 00 00       	call   f0103862 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01007fa:	00 
f01007fb:	c7 04 24 68 50 10 f0 	movl   $0xf0105068,(%esp)
f0100802:	e8 5b 30 00 00       	call   f0103862 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100807:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010080e:	00 
f010080f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100816:	f0 
f0100817:	c7 04 24 90 50 10 f0 	movl   $0xf0105090,(%esp)
f010081e:	e8 3f 30 00 00       	call   f0103862 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100823:	c7 44 24 08 b7 4c 10 	movl   $0x104cb7,0x8(%esp)
f010082a:	00 
f010082b:	c7 44 24 04 b7 4c 10 	movl   $0xf0104cb7,0x4(%esp)
f0100832:	f0 
f0100833:	c7 04 24 b4 50 10 f0 	movl   $0xf01050b4,(%esp)
f010083a:	e8 23 30 00 00       	call   f0103862 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010083f:	c7 44 24 08 78 50 18 	movl   $0x185078,0x8(%esp)
f0100846:	00 
f0100847:	c7 44 24 04 78 50 18 	movl   $0xf0185078,0x4(%esp)
f010084e:	f0 
f010084f:	c7 04 24 d8 50 10 f0 	movl   $0xf01050d8,(%esp)
f0100856:	e8 07 30 00 00       	call   f0103862 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010085b:	c7 44 24 08 90 6f 18 	movl   $0x186f90,0x8(%esp)
f0100862:	00 
f0100863:	c7 44 24 04 90 6f 18 	movl   $0xf0186f90,0x4(%esp)
f010086a:	f0 
f010086b:	c7 04 24 fc 50 10 f0 	movl   $0xf01050fc,(%esp)
f0100872:	e8 eb 2f 00 00       	call   f0103862 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100877:	b8 8f 73 18 f0       	mov    $0xf018738f,%eax
f010087c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100881:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100886:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010088c:	85 c0                	test   %eax,%eax
f010088e:	0f 48 c2             	cmovs  %edx,%eax
f0100891:	c1 f8 0a             	sar    $0xa,%eax
f0100894:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100898:	c7 04 24 20 51 10 f0 	movl   $0xf0105120,(%esp)
f010089f:	e8 be 2f 00 00       	call   f0103862 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008a9:	c9                   	leave  
f01008aa:	c3                   	ret    

f01008ab <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008ab:	55                   	push   %ebp
f01008ac:	89 e5                	mov    %esp,%ebp
f01008ae:	57                   	push   %edi
f01008af:	56                   	push   %esi
f01008b0:	53                   	push   %ebx
f01008b1:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008b4:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f01008b6:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f01008b9:	eb 77                	jmp    f0100932 <mon_backtrace+0x87>
	uint32_t eip=*(uint32_t *)(ebp+4);
f01008bb:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f01008be:	8b 43 18             	mov    0x18(%ebx),%eax
f01008c1:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01008c5:	8b 43 14             	mov    0x14(%ebx),%eax
f01008c8:	89 44 24 18          	mov    %eax,0x18(%esp)
f01008cc:	8b 43 10             	mov    0x10(%ebx),%eax
f01008cf:	89 44 24 14          	mov    %eax,0x14(%esp)
f01008d3:	8b 43 0c             	mov    0xc(%ebx),%eax
f01008d6:	89 44 24 10          	mov    %eax,0x10(%esp)
f01008da:	8b 43 08             	mov    0x8(%ebx),%eax
f01008dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008e1:	89 74 24 08          	mov    %esi,0x8(%esp)
f01008e5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01008e9:	c7 04 24 4c 51 10 f0 	movl   $0xf010514c,(%esp)
f01008f0:	e8 6d 2f 00 00       	call   f0103862 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f01008f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008f9:	89 34 24             	mov    %esi,(%esp)
f01008fc:	e8 d2 34 00 00       	call   f0103dd3 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100901:	2b 75 e0             	sub    -0x20(%ebp),%esi
f0100904:	89 74 24 14          	mov    %esi,0x14(%esp)
f0100908:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010090b:	89 44 24 10          	mov    %eax,0x10(%esp)
f010090f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100912:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100916:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100919:	89 44 24 08          	mov    %eax,0x8(%esp)
f010091d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100920:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100924:	c7 04 24 ec 4f 10 f0 	movl   $0xf0104fec,(%esp)
f010092b:	e8 32 2f 00 00       	call   f0103862 <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f0100930:	8b 1b                	mov    (%ebx),%ebx
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f0100932:	85 db                	test   %ebx,%ebx
f0100934:	75 85                	jne    f01008bb <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f0100936:	b8 00 00 00 00       	mov    $0x0,%eax
f010093b:	83 c4 4c             	add    $0x4c,%esp
f010093e:	5b                   	pop    %ebx
f010093f:	5e                   	pop    %esi
f0100940:	5f                   	pop    %edi
f0100941:	5d                   	pop    %ebp
f0100942:	c3                   	ret    

f0100943 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100943:	55                   	push   %ebp
f0100944:	89 e5                	mov    %esp,%ebp
f0100946:	57                   	push   %edi
f0100947:	56                   	push   %esi
f0100948:	53                   	push   %ebx
f0100949:	83 ec 5c             	sub    $0x5c,%esp
f010094c:	89 c3                	mov    %eax,%ebx
f010094e:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100951:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100958:	be 00 00 00 00       	mov    $0x0,%esi
f010095d:	eb 0a                	jmp    f0100969 <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010095f:	c6 03 00             	movb   $0x0,(%ebx)
f0100962:	89 f7                	mov    %esi,%edi
f0100964:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100967:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100969:	0f b6 03             	movzbl (%ebx),%eax
f010096c:	84 c0                	test   %al,%al
f010096e:	74 6c                	je     f01009dc <runcmd+0x99>
f0100970:	0f be c0             	movsbl %al,%eax
f0100973:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100977:	c7 04 24 03 50 10 f0 	movl   $0xf0105003,(%esp)
f010097e:	e8 67 3e 00 00       	call   f01047ea <strchr>
f0100983:	85 c0                	test   %eax,%eax
f0100985:	75 d8                	jne    f010095f <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f0100987:	80 3b 00             	cmpb   $0x0,(%ebx)
f010098a:	74 50                	je     f01009dc <runcmd+0x99>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010098c:	83 fe 0f             	cmp    $0xf,%esi
f010098f:	90                   	nop
f0100990:	75 1e                	jne    f01009b0 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100992:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100999:	00 
f010099a:	c7 04 24 08 50 10 f0 	movl   $0xf0105008,(%esp)
f01009a1:	e8 bc 2e 00 00       	call   f0103862 <cprintf>
			return 0;
f01009a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01009ab:	e9 9c 00 00 00       	jmp    f0100a4c <runcmd+0x109>
		}
		argv[argc++] = buf;
f01009b0:	8d 7e 01             	lea    0x1(%esi),%edi
f01009b3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f01009b7:	eb 03                	jmp    f01009bc <runcmd+0x79>
			buf++;
f01009b9:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009bc:	0f b6 03             	movzbl (%ebx),%eax
f01009bf:	84 c0                	test   %al,%al
f01009c1:	74 a4                	je     f0100967 <runcmd+0x24>
f01009c3:	0f be c0             	movsbl %al,%eax
f01009c6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ca:	c7 04 24 03 50 10 f0 	movl   $0xf0105003,(%esp)
f01009d1:	e8 14 3e 00 00       	call   f01047ea <strchr>
f01009d6:	85 c0                	test   %eax,%eax
f01009d8:	74 df                	je     f01009b9 <runcmd+0x76>
f01009da:	eb 8b                	jmp    f0100967 <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f01009dc:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009e3:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f01009e4:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f01009e9:	85 f6                	test   %esi,%esi
f01009eb:	74 5f                	je     f0100a4c <runcmd+0x109>
f01009ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01009f2:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009f5:	8b 04 85 e0 51 10 f0 	mov    -0xfefae20(,%eax,4),%eax
f01009fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a00:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a03:	89 04 24             	mov    %eax,(%esp)
f0100a06:	e8 81 3d 00 00       	call   f010478c <strcmp>
f0100a0b:	85 c0                	test   %eax,%eax
f0100a0d:	75 1d                	jne    f0100a2c <runcmd+0xe9>
			return commands[i].func(argc, argv, tf);
f0100a0f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a12:	8b 4d a4             	mov    -0x5c(%ebp),%ecx
f0100a15:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100a19:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a1c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a20:	89 34 24             	mov    %esi,(%esp)
f0100a23:	ff 14 85 e8 51 10 f0 	call   *-0xfefae18(,%eax,4)
f0100a2a:	eb 20                	jmp    f0100a4c <runcmd+0x109>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a2c:	83 c3 01             	add    $0x1,%ebx
f0100a2f:	83 fb 03             	cmp    $0x3,%ebx
f0100a32:	75 be                	jne    f01009f2 <runcmd+0xaf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a34:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a3b:	c7 04 24 25 50 10 f0 	movl   $0xf0105025,(%esp)
f0100a42:	e8 1b 2e 00 00       	call   f0103862 <cprintf>
	return 0;
f0100a47:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100a4c:	83 c4 5c             	add    $0x5c,%esp
f0100a4f:	5b                   	pop    %ebx
f0100a50:	5e                   	pop    %esi
f0100a51:	5f                   	pop    %edi
f0100a52:	5d                   	pop    %ebp
f0100a53:	c3                   	ret    

f0100a54 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100a54:	55                   	push   %ebp
f0100a55:	89 e5                	mov    %esp,%ebp
f0100a57:	53                   	push   %ebx
f0100a58:	83 ec 14             	sub    $0x14,%esp
f0100a5b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100a5e:	c7 04 24 80 51 10 f0 	movl   $0xf0105180,(%esp)
f0100a65:	e8 f8 2d 00 00       	call   f0103862 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a6a:	c7 04 24 a4 51 10 f0 	movl   $0xf01051a4,(%esp)
f0100a71:	e8 ec 2d 00 00       	call   f0103862 <cprintf>

	if (tf != NULL)
f0100a76:	85 db                	test   %ebx,%ebx
f0100a78:	74 08                	je     f0100a82 <monitor+0x2e>
		print_trapframe(tf);
f0100a7a:	89 1c 24             	mov    %ebx,(%esp)
f0100a7d:	e8 4e 2f 00 00       	call   f01039d0 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a82:	c7 04 24 3b 50 10 f0 	movl   $0xf010503b,(%esp)
f0100a89:	e8 42 3b 00 00       	call   f01045d0 <readline>
		if (buf != NULL)
f0100a8e:	85 c0                	test   %eax,%eax
f0100a90:	74 f0                	je     f0100a82 <monitor+0x2e>
			if (runcmd(buf, tf) < 0)
f0100a92:	89 da                	mov    %ebx,%edx
f0100a94:	e8 aa fe ff ff       	call   f0100943 <runcmd>
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	79 e5                	jns    f0100a82 <monitor+0x2e>
				break;
	}
}
f0100a9d:	83 c4 14             	add    $0x14,%esp
f0100aa0:	5b                   	pop    %ebx
f0100aa1:	5d                   	pop    %ebp
f0100aa2:	c3                   	ret    

f0100aa3 <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f0100aa3:	55                   	push   %ebp
f0100aa4:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100aa6:	0f 01 38             	invlpg (%eax)
}
f0100aa9:	5d                   	pop    %ebp
f0100aaa:	c3                   	ret    

f0100aab <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100aab:	55                   	push   %ebp
f0100aac:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100aae:	0f 22 c0             	mov    %eax,%cr0
}
f0100ab1:	5d                   	pop    %ebp
f0100ab2:	c3                   	ret    

f0100ab3 <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100ab3:	55                   	push   %ebp
f0100ab4:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100ab6:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100ab9:	5d                   	pop    %ebp
f0100aba:	c3                   	ret    

f0100abb <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100abb:	55                   	push   %ebp
f0100abc:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100abe:	0f 22 d8             	mov    %eax,%cr3
}
f0100ac1:	5d                   	pop    %ebp
f0100ac2:	c3                   	ret    

f0100ac3 <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100ac3:	55                   	push   %ebp
f0100ac4:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100ac6:	2b 05 8c 6f 18 f0    	sub    0xf0186f8c,%eax
f0100acc:	c1 f8 03             	sar    $0x3,%eax
f0100acf:	c1 e0 0c             	shl    $0xc,%eax
}
f0100ad2:	5d                   	pop    %ebp
f0100ad3:	c3                   	ret    

f0100ad4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ad4:	55                   	push   %ebp
f0100ad5:	89 e5                	mov    %esp,%ebp
f0100ad7:	56                   	push   %esi
f0100ad8:	53                   	push   %ebx
f0100ad9:	83 ec 10             	sub    $0x10,%esp
f0100adc:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ade:	89 04 24             	mov    %eax,(%esp)
f0100ae1:	e8 f5 2c 00 00       	call   f01037db <mc146818_read>
f0100ae6:	89 c6                	mov    %eax,%esi
f0100ae8:	83 c3 01             	add    $0x1,%ebx
f0100aeb:	89 1c 24             	mov    %ebx,(%esp)
f0100aee:	e8 e8 2c 00 00       	call   f01037db <mc146818_read>
f0100af3:	c1 e0 08             	shl    $0x8,%eax
f0100af6:	09 f0                	or     %esi,%eax
}
f0100af8:	83 c4 10             	add    $0x10,%esp
f0100afb:	5b                   	pop    %ebx
f0100afc:	5e                   	pop    %esi
f0100afd:	5d                   	pop    %ebp
f0100afe:	c3                   	ret    

f0100aff <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100aff:	55                   	push   %ebp
f0100b00:	89 e5                	mov    %esp,%ebp
f0100b02:	56                   	push   %esi
f0100b03:	53                   	push   %ebx
f0100b04:	83 ec 10             	sub    $0x10,%esp
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100b07:	b8 15 00 00 00       	mov    $0x15,%eax
f0100b0c:	e8 c3 ff ff ff       	call   f0100ad4 <nvram_read>
f0100b11:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100b13:	b8 17 00 00 00       	mov    $0x17,%eax
f0100b18:	e8 b7 ff ff ff       	call   f0100ad4 <nvram_read>
f0100b1d:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100b1f:	b8 34 00 00 00       	mov    $0x34,%eax
f0100b24:	e8 ab ff ff ff       	call   f0100ad4 <nvram_read>
f0100b29:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100b2c:	85 c0                	test   %eax,%eax
f0100b2e:	74 07                	je     f0100b37 <i386_detect_memory+0x38>
		totalmem = 16 * 1024 + ext16mem;
f0100b30:	05 00 40 00 00       	add    $0x4000,%eax
f0100b35:	eb 0b                	jmp    f0100b42 <i386_detect_memory+0x43>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100b37:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100b3d:	85 f6                	test   %esi,%esi
f0100b3f:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100b42:	89 c2                	mov    %eax,%edx
f0100b44:	c1 ea 02             	shr    $0x2,%edx
f0100b47:	89 15 84 6f 18 f0    	mov    %edx,0xf0186f84
	npages_basemem = basemem / (PGSIZE / 1024);
f0100b4d:	89 da                	mov    %ebx,%edx
f0100b4f:	c1 ea 02             	shr    $0x2,%edx
f0100b52:	89 15 c0 52 18 f0    	mov    %edx,0xf01852c0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b58:	89 c2                	mov    %eax,%edx
f0100b5a:	29 da                	sub    %ebx,%edx
f0100b5c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100b60:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100b64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b68:	c7 04 24 04 52 10 f0 	movl   $0xf0105204,(%esp)
f0100b6f:	e8 ee 2c 00 00       	call   f0103862 <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100b74:	83 c4 10             	add    $0x10,%esp
f0100b77:	5b                   	pop    %ebx
f0100b78:	5e                   	pop    %esi
f0100b79:	5d                   	pop    %ebp
f0100b7a:	c3                   	ret    

f0100b7b <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100b7b:	55                   	push   %ebp
f0100b7c:	89 e5                	mov    %esp,%ebp
f0100b7e:	53                   	push   %ebx
f0100b7f:	83 ec 14             	sub    $0x14,%esp
	if (PGNUM(pa) >= npages)
f0100b82:	89 cb                	mov    %ecx,%ebx
f0100b84:	c1 eb 0c             	shr    $0xc,%ebx
f0100b87:	3b 1d 84 6f 18 f0    	cmp    0xf0186f84,%ebx
f0100b8d:	72 18                	jb     f0100ba7 <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b8f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100b93:	c7 44 24 08 40 52 10 	movl   $0xf0105240,0x8(%esp)
f0100b9a:	f0 
f0100b9b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b9f:	89 04 24             	mov    %eax,(%esp)
f0100ba2:	e8 1f f5 ff ff       	call   f01000c6 <_panic>
	return (void *)(pa + KERNBASE);
f0100ba7:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100bad:	83 c4 14             	add    $0x14,%esp
f0100bb0:	5b                   	pop    %ebx
f0100bb1:	5d                   	pop    %ebp
f0100bb2:	c3                   	ret    

f0100bb3 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100bb3:	55                   	push   %ebp
f0100bb4:	89 e5                	mov    %esp,%ebp
f0100bb6:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100bb9:	e8 05 ff ff ff       	call   f0100ac3 <page2pa>
f0100bbe:	89 c1                	mov    %eax,%ecx
f0100bc0:	ba 56 00 00 00       	mov    $0x56,%edx
f0100bc5:	b8 ed 59 10 f0       	mov    $0xf01059ed,%eax
f0100bca:	e8 ac ff ff ff       	call   f0100b7b <_kaddr>
}
f0100bcf:	c9                   	leave  
f0100bd0:	c3                   	ret    

f0100bd1 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100bd1:	55                   	push   %ebp
f0100bd2:	89 e5                	mov    %esp,%ebp
f0100bd4:	53                   	push   %ebx
f0100bd5:	83 ec 04             	sub    $0x4,%esp
f0100bd8:	89 d3                	mov    %edx,%ebx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bda:	c1 ea 16             	shr    $0x16,%edx
	if (!(*pgdir & PTE_P))
f0100bdd:	8b 0c 90             	mov    (%eax,%edx,4),%ecx
		return ~0;
f0100be0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100be5:	f6 c1 01             	test   $0x1,%cl
f0100be8:	74 4d                	je     f0100c37 <check_va2pa+0x66>
		return ~0;
	if (*pgdir & PTE_PS)
f0100bea:	f6 c1 80             	test   $0x80,%cl
f0100bed:	74 11                	je     f0100c00 <check_va2pa+0x2f>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100bef:	89 d8                	mov    %ebx,%eax
f0100bf1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100bf6:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100bfc:	09 c8                	or     %ecx,%eax
f0100bfe:	eb 37                	jmp    f0100c37 <check_va2pa+0x66>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c00:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c06:	ba 1b 03 00 00       	mov    $0x31b,%edx
f0100c0b:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0100c10:	e8 66 ff ff ff       	call   f0100b7b <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100c15:	c1 eb 0c             	shr    $0xc,%ebx
f0100c18:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0100c1e:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100c21:	89 c2                	mov    %eax,%edx
f0100c23:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c26:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c2b:	85 d2                	test   %edx,%edx
f0100c2d:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c32:	0f 44 c2             	cmove  %edx,%eax
f0100c35:	eb 00                	jmp    f0100c37 <check_va2pa+0x66>
}
f0100c37:	83 c4 04             	add    $0x4,%esp
f0100c3a:	5b                   	pop    %ebx
f0100c3b:	5d                   	pop    %ebp
f0100c3c:	c3                   	ret    

f0100c3d <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c3d:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100c43:	77 1e                	ja     f0100c63 <_paddr+0x26>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100c45:	55                   	push   %ebp
f0100c46:	89 e5                	mov    %esp,%ebp
f0100c48:	83 ec 18             	sub    $0x18,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c4b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c4f:	c7 44 24 08 64 52 10 	movl   $0xf0105264,0x8(%esp)
f0100c56:	f0 
f0100c57:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c5b:	89 04 24             	mov    %eax,(%esp)
f0100c5e:	e8 63 f4 ff ff       	call   f01000c6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100c63:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100c69:	c3                   	ret    

f0100c6a <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100c6a:	83 3d b8 52 18 f0 00 	cmpl   $0x0,0xf01852b8
f0100c71:	75 11                	jne    f0100c84 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c73:	ba 8f 7f 18 f0       	mov    $0xf0187f8f,%edx
f0100c78:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c7e:	89 15 b8 52 18 f0    	mov    %edx,0xf01852b8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100c84:	85 c0                	test   %eax,%eax
f0100c86:	75 06                	jne    f0100c8e <boot_alloc+0x24>
f0100c88:	a1 b8 52 18 f0       	mov    0xf01852b8,%eax
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
	return (void*) result;
}
f0100c8d:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100c8e:	55                   	push   %ebp
f0100c8f:	89 e5                	mov    %esp,%ebp
f0100c91:	53                   	push   %ebx
f0100c92:	83 ec 14             	sub    $0x14,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100c95:	8b 1d b8 52 18 f0    	mov    0xf01852b8,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100c9b:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100ca1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100ca7:	01 d9                	add    %ebx,%ecx
f0100ca9:	89 0d b8 52 18 f0    	mov    %ecx,0xf01852b8
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100caf:	ba 6e 00 00 00       	mov    $0x6e,%edx
f0100cb4:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0100cb9:	e8 7f ff ff ff       	call   f0100c3d <_paddr>
f0100cbe:	8b 15 84 6f 18 f0    	mov    0xf0186f84,%edx
f0100cc4:	c1 e2 0c             	shl    $0xc,%edx
f0100cc7:	39 d0                	cmp    %edx,%eax
f0100cc9:	76 1c                	jbe    f0100ce7 <boot_alloc+0x7d>
f0100ccb:	c7 44 24 08 07 5a 10 	movl   $0xf0105a07,0x8(%esp)
f0100cd2:	f0 
f0100cd3:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100cda:	00 
f0100cdb:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100ce2:	e8 df f3 ff ff       	call   f01000c6 <_panic>
	return (void*) result;
f0100ce7:	89 d8                	mov    %ebx,%eax
}
f0100ce9:	83 c4 14             	add    $0x14,%esp
f0100cec:	5b                   	pop    %ebx
f0100ced:	5d                   	pop    %ebp
f0100cee:	c3                   	ret    

f0100cef <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100cef:	55                   	push   %ebp
f0100cf0:	89 e5                	mov    %esp,%ebp
f0100cf2:	57                   	push   %edi
f0100cf3:	56                   	push   %esi
f0100cf4:	53                   	push   %ebx
f0100cf5:	83 ec 2c             	sub    $0x2c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100cf8:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100cfe:	a1 84 6f 18 f0       	mov    0xf0186f84,%eax
f0100d03:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d06:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100d0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100d12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100d15:	a1 8c 6f 18 f0       	mov    0xf0186f8c,%eax
f0100d1a:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100d1d:	be 00 00 00 00       	mov    $0x0,%esi
f0100d22:	eb 51                	jmp    f0100d75 <check_kern_pgdir+0x86>
f0100d24:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100d2a:	89 d8                	mov    %ebx,%eax
f0100d2c:	e8 a0 fe ff ff       	call   f0100bd1 <check_va2pa>
f0100d31:	89 c7                	mov    %eax,%edi
f0100d33:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d36:	ba dd 02 00 00       	mov    $0x2dd,%edx
f0100d3b:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0100d40:	e8 f8 fe ff ff       	call   f0100c3d <_paddr>
f0100d45:	01 f0                	add    %esi,%eax
f0100d47:	39 c7                	cmp    %eax,%edi
f0100d49:	74 24                	je     f0100d6f <check_kern_pgdir+0x80>
f0100d4b:	c7 44 24 0c 88 52 10 	movl   $0xf0105288,0xc(%esp)
f0100d52:	f0 
f0100d53:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100d5a:	f0 
f0100d5b:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0100d62:	00 
f0100d63:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100d6a:	e8 57 f3 ff ff       	call   f01000c6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100d6f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d75:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100d78:	72 aa                	jb     f0100d24 <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0100d7a:	a1 c8 52 18 f0       	mov    0xf01852c8,%eax
f0100d7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d82:	be 00 00 00 00       	mov    $0x0,%esi
f0100d87:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
f0100d8d:	89 d8                	mov    %ebx,%eax
f0100d8f:	e8 3d fe ff ff       	call   f0100bd1 <check_va2pa>
f0100d94:	89 c7                	mov    %eax,%edi
f0100d96:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d99:	ba e2 02 00 00       	mov    $0x2e2,%edx
f0100d9e:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0100da3:	e8 95 fe ff ff       	call   f0100c3d <_paddr>
f0100da8:	01 f0                	add    %esi,%eax
f0100daa:	39 c7                	cmp    %eax,%edi
f0100dac:	74 24                	je     f0100dd2 <check_kern_pgdir+0xe3>
f0100dae:	c7 44 24 0c bc 52 10 	movl   $0xf01052bc,0xc(%esp)
f0100db5:	f0 
f0100db6:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100dbd:	f0 
f0100dbe:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0100dc5:	00 
f0100dc6:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100dcd:	e8 f4 f2 ff ff       	call   f01000c6 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100dd2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100dd8:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0100dde:	75 a7                	jne    f0100d87 <check_kern_pgdir+0x98>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100de0:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100de3:	c1 e7 0c             	shl    $0xc,%edi
f0100de6:	be 00 00 00 00       	mov    $0x0,%esi
f0100deb:	eb 3b                	jmp    f0100e28 <check_kern_pgdir+0x139>
f0100ded:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100df3:	89 d8                	mov    %ebx,%eax
f0100df5:	e8 d7 fd ff ff       	call   f0100bd1 <check_va2pa>
f0100dfa:	39 f0                	cmp    %esi,%eax
f0100dfc:	74 24                	je     f0100e22 <check_kern_pgdir+0x133>
f0100dfe:	c7 44 24 0c f0 52 10 	movl   $0xf01052f0,0xc(%esp)
f0100e05:	f0 
f0100e06:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100e0d:	f0 
f0100e0e:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0100e15:	00 
f0100e16:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100e1d:	e8 a4 f2 ff ff       	call   f01000c6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100e22:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100e28:	39 fe                	cmp    %edi,%esi
f0100e2a:	72 c1                	jb     f0100ded <check_kern_pgdir+0xfe>
f0100e2c:	be 00 00 00 00       	mov    $0x0,%esi
f0100e31:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100e37:	89 d8                	mov    %ebx,%eax
f0100e39:	e8 93 fd ff ff       	call   f0100bd1 <check_va2pa>
f0100e3e:	89 c7                	mov    %eax,%edi
f0100e40:	b9 00 20 11 f0       	mov    $0xf0112000,%ecx
f0100e45:	ba ea 02 00 00       	mov    $0x2ea,%edx
f0100e4a:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0100e4f:	e8 e9 fd ff ff       	call   f0100c3d <_paddr>
f0100e54:	01 f0                	add    %esi,%eax
f0100e56:	39 c7                	cmp    %eax,%edi
f0100e58:	74 24                	je     f0100e7e <check_kern_pgdir+0x18f>
f0100e5a:	c7 44 24 0c 18 53 10 	movl   $0xf0105318,0xc(%esp)
f0100e61:	f0 
f0100e62:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100e69:	f0 
f0100e6a:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0100e71:	00 
f0100e72:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100e79:	e8 48 f2 ff ff       	call   f01000c6 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100e7e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100e84:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100e8a:	75 a5                	jne    f0100e31 <check_kern_pgdir+0x142>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100e8c:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100e91:	89 d8                	mov    %ebx,%eax
f0100e93:	e8 39 fd ff ff       	call   f0100bd1 <check_va2pa>
f0100e98:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100e9b:	75 0a                	jne    f0100ea7 <check_kern_pgdir+0x1b8>
f0100e9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ea2:	e9 f0 00 00 00       	jmp    f0100f97 <check_kern_pgdir+0x2a8>
f0100ea7:	c7 44 24 0c 60 53 10 	movl   $0xf0105360,0xc(%esp)
f0100eae:	f0 
f0100eaf:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100eb6:	f0 
f0100eb7:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0100ebe:	00 
f0100ebf:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100ec6:	e8 fb f1 ff ff       	call   f01000c6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100ecb:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0100ed0:	72 3c                	jb     f0100f0e <check_kern_pgdir+0x21f>
f0100ed2:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100ed7:	76 07                	jbe    f0100ee0 <check_kern_pgdir+0x1f1>
f0100ed9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100ede:	75 2e                	jne    f0100f0e <check_kern_pgdir+0x21f>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0100ee0:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100ee4:	0f 85 aa 00 00 00    	jne    f0100f94 <check_kern_pgdir+0x2a5>
f0100eea:	c7 44 24 0c 2f 5a 10 	movl   $0xf0105a2f,0xc(%esp)
f0100ef1:	f0 
f0100ef2:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100ef9:	f0 
f0100efa:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0100f01:	00 
f0100f02:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100f09:	e8 b8 f1 ff ff       	call   f01000c6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100f0e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100f13:	76 55                	jbe    f0100f6a <check_kern_pgdir+0x27b>
				assert(pgdir[i] & PTE_P);
f0100f15:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100f18:	f6 c2 01             	test   $0x1,%dl
f0100f1b:	75 24                	jne    f0100f41 <check_kern_pgdir+0x252>
f0100f1d:	c7 44 24 0c 2f 5a 10 	movl   $0xf0105a2f,0xc(%esp)
f0100f24:	f0 
f0100f25:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100f2c:	f0 
f0100f2d:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0100f34:	00 
f0100f35:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100f3c:	e8 85 f1 ff ff       	call   f01000c6 <_panic>
				assert(pgdir[i] & PTE_W);
f0100f41:	f6 c2 02             	test   $0x2,%dl
f0100f44:	75 4e                	jne    f0100f94 <check_kern_pgdir+0x2a5>
f0100f46:	c7 44 24 0c 40 5a 10 	movl   $0xf0105a40,0xc(%esp)
f0100f4d:	f0 
f0100f4e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100f55:	f0 
f0100f56:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0100f5d:	00 
f0100f5e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100f65:	e8 5c f1 ff ff       	call   f01000c6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100f6a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100f6e:	74 24                	je     f0100f94 <check_kern_pgdir+0x2a5>
f0100f70:	c7 44 24 0c 51 5a 10 	movl   $0xf0105a51,0xc(%esp)
f0100f77:	f0 
f0100f78:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0100f7f:	f0 
f0100f80:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0100f87:	00 
f0100f88:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100f8f:	e8 32 f1 ff ff       	call   f01000c6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100f94:	83 c0 01             	add    $0x1,%eax
f0100f97:	3d 00 04 00 00       	cmp    $0x400,%eax
f0100f9c:	0f 85 29 ff ff ff    	jne    f0100ecb <check_kern_pgdir+0x1dc>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100fa2:	c7 04 24 90 53 10 f0 	movl   $0xf0105390,(%esp)
f0100fa9:	e8 b4 28 00 00       	call   f0103862 <cprintf>
			assert(PTE_ADDR(pgdir[i]) == (i - kern_pdx) << PDXSHIFT);
		}
		cprintf("check_kern_pgdir_pse() succeeded!\n");
	#endif

}
f0100fae:	83 c4 2c             	add    $0x2c,%esp
f0100fb1:	5b                   	pop    %ebx
f0100fb2:	5e                   	pop    %esi
f0100fb3:	5f                   	pop    %edi
f0100fb4:	5d                   	pop    %ebp
f0100fb5:	c3                   	ret    

f0100fb6 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100fb6:	55                   	push   %ebp
f0100fb7:	89 e5                	mov    %esp,%ebp
f0100fb9:	57                   	push   %edi
f0100fba:	56                   	push   %esi
f0100fbb:	53                   	push   %ebx
f0100fbc:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fbf:	84 c0                	test   %al,%al
f0100fc1:	0f 85 aa 02 00 00    	jne    f0101271 <check_page_free_list+0x2bb>
f0100fc7:	e9 b8 02 00 00       	jmp    f0101284 <check_page_free_list+0x2ce>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100fcc:	c7 44 24 08 b0 53 10 	movl   $0xf01053b0,0x8(%esp)
f0100fd3:	f0 
f0100fd4:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100fdb:	00 
f0100fdc:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0100fe3:	e8 de f0 ff ff       	call   f01000c6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100fe8:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100feb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fee:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100ff1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ff4:	89 d8                	mov    %ebx,%eax
f0100ff6:	e8 c8 fa ff ff       	call   f0100ac3 <page2pa>
f0100ffb:	c1 e8 16             	shr    $0x16,%eax
f0100ffe:	85 c0                	test   %eax,%eax
f0101000:	0f 95 c0             	setne  %al
f0101003:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0101006:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f010100a:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f010100c:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101010:	8b 1b                	mov    (%ebx),%ebx
f0101012:	85 db                	test   %ebx,%ebx
f0101014:	75 de                	jne    f0100ff4 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101016:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101019:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010101f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101022:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101025:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101027:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010102a:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f010102f:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101034:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
f010103a:	eb 2f                	jmp    f010106b <check_page_free_list+0xb5>
		if (PDX(page2pa(pp)) < pdx_limit)
f010103c:	89 d8                	mov    %ebx,%eax
f010103e:	e8 80 fa ff ff       	call   f0100ac3 <page2pa>
f0101043:	c1 e8 16             	shr    $0x16,%eax
f0101046:	39 f0                	cmp    %esi,%eax
f0101048:	73 1f                	jae    f0101069 <check_page_free_list+0xb3>
			memset(page2kva(pp), 0x97, 128);
f010104a:	89 d8                	mov    %ebx,%eax
f010104c:	e8 62 fb ff ff       	call   f0100bb3 <page2kva>
f0101051:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0101058:	00 
f0101059:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101060:	00 
f0101061:	89 04 24             	mov    %eax,(%esp)
f0101064:	e8 be 37 00 00       	call   f0104827 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101069:	8b 1b                	mov    (%ebx),%ebx
f010106b:	85 db                	test   %ebx,%ebx
f010106d:	75 cd                	jne    f010103c <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f010106f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101074:	e8 f1 fb ff ff       	call   f0100c6a <boot_alloc>
f0101079:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010107c:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101082:	8b 35 8c 6f 18 f0    	mov    0xf0186f8c,%esi
		assert(pp < pages + npages);
f0101088:	a1 84 6f 18 f0       	mov    0xf0186f84,%eax
f010108d:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0101090:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101093:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101096:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f010109d:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010a2:	e9 70 01 00 00       	jmp    f0101217 <check_page_free_list+0x261>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01010a7:	39 f3                	cmp    %esi,%ebx
f01010a9:	73 24                	jae    f01010cf <check_page_free_list+0x119>
f01010ab:	c7 44 24 0c 5f 5a 10 	movl   $0xf0105a5f,0xc(%esp)
f01010b2:	f0 
f01010b3:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01010ba:	f0 
f01010bb:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f01010c2:	00 
f01010c3:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01010ca:	e8 f7 ef ff ff       	call   f01000c6 <_panic>
		assert(pp < pages + npages);
f01010cf:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01010d2:	72 24                	jb     f01010f8 <check_page_free_list+0x142>
f01010d4:	c7 44 24 0c 6b 5a 10 	movl   $0xf0105a6b,0xc(%esp)
f01010db:	f0 
f01010dc:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01010e3:	f0 
f01010e4:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01010eb:	00 
f01010ec:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01010f3:	e8 ce ef ff ff       	call   f01000c6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010f8:	89 d8                	mov    %ebx,%eax
f01010fa:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01010fd:	a8 07                	test   $0x7,%al
f01010ff:	74 24                	je     f0101125 <check_page_free_list+0x16f>
f0101101:	c7 44 24 0c d4 53 10 	movl   $0xf01053d4,0xc(%esp)
f0101108:	f0 
f0101109:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101110:	f0 
f0101111:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f0101118:	00 
f0101119:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101120:	e8 a1 ef ff ff       	call   f01000c6 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101125:	89 d8                	mov    %ebx,%eax
f0101127:	e8 97 f9 ff ff       	call   f0100ac3 <page2pa>
f010112c:	85 c0                	test   %eax,%eax
f010112e:	75 24                	jne    f0101154 <check_page_free_list+0x19e>
f0101130:	c7 44 24 0c 7f 5a 10 	movl   $0xf0105a7f,0xc(%esp)
f0101137:	f0 
f0101138:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010113f:	f0 
f0101140:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0101147:	00 
f0101148:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010114f:	e8 72 ef ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101154:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101159:	75 24                	jne    f010117f <check_page_free_list+0x1c9>
f010115b:	c7 44 24 0c 90 5a 10 	movl   $0xf0105a90,0xc(%esp)
f0101162:	f0 
f0101163:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010116a:	f0 
f010116b:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0101172:	00 
f0101173:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010117a:	e8 47 ef ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010117f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101184:	75 24                	jne    f01011aa <check_page_free_list+0x1f4>
f0101186:	c7 44 24 0c 08 54 10 	movl   $0xf0105408,0xc(%esp)
f010118d:	f0 
f010118e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101195:	f0 
f0101196:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f010119d:	00 
f010119e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01011a5:	e8 1c ef ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01011aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01011af:	75 24                	jne    f01011d5 <check_page_free_list+0x21f>
f01011b1:	c7 44 24 0c a9 5a 10 	movl   $0xf0105aa9,0xc(%esp)
f01011b8:	f0 
f01011b9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01011c0:	f0 
f01011c1:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f01011c8:	00 
f01011c9:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01011d0:	e8 f1 ee ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01011d5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01011da:	76 30                	jbe    f010120c <check_page_free_list+0x256>
f01011dc:	89 d8                	mov    %ebx,%eax
f01011de:	e8 d0 f9 ff ff       	call   f0100bb3 <page2kva>
f01011e3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01011e6:	76 29                	jbe    f0101211 <check_page_free_list+0x25b>
f01011e8:	c7 44 24 0c 2c 54 10 	movl   $0xf010542c,0xc(%esp)
f01011ef:	f0 
f01011f0:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01011f7:	f0 
f01011f8:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01011ff:	00 
f0101200:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101207:	e8 ba ee ff ff       	call   f01000c6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010120c:	83 c7 01             	add    $0x1,%edi
f010120f:	eb 04                	jmp    f0101215 <check_page_free_list+0x25f>
		else
			++nfree_extmem;
f0101211:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101215:	8b 1b                	mov    (%ebx),%ebx
f0101217:	85 db                	test   %ebx,%ebx
f0101219:	0f 85 88 fe ff ff    	jne    f01010a7 <check_page_free_list+0xf1>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f010121f:	85 ff                	test   %edi,%edi
f0101221:	7f 24                	jg     f0101247 <check_page_free_list+0x291>
f0101223:	c7 44 24 0c c3 5a 10 	movl   $0xf0105ac3,0xc(%esp)
f010122a:	f0 
f010122b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101232:	f0 
f0101233:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010123a:	00 
f010123b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101242:	e8 7f ee ff ff       	call   f01000c6 <_panic>
	assert(nfree_extmem > 0);
f0101247:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010124b:	7f 4e                	jg     f010129b <check_page_free_list+0x2e5>
f010124d:	c7 44 24 0c d5 5a 10 	movl   $0xf0105ad5,0xc(%esp)
f0101254:	f0 
f0101255:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010125c:	f0 
f010125d:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101264:	00 
f0101265:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010126c:	e8 55 ee ff ff       	call   f01000c6 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101271:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
f0101277:	85 db                	test   %ebx,%ebx
f0101279:	0f 85 69 fd ff ff    	jne    f0100fe8 <check_page_free_list+0x32>
f010127f:	e9 48 fd ff ff       	jmp    f0100fcc <check_page_free_list+0x16>
f0101284:	83 3d bc 52 18 f0 00 	cmpl   $0x0,0xf01852bc
f010128b:	0f 84 3b fd ff ff    	je     f0100fcc <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101291:	be 00 04 00 00       	mov    $0x400,%esi
f0101296:	e9 99 fd ff ff       	jmp    f0101034 <check_page_free_list+0x7e>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f010129b:	83 c4 3c             	add    $0x3c,%esp
f010129e:	5b                   	pop    %ebx
f010129f:	5e                   	pop    %esi
f01012a0:	5f                   	pop    %edi
f01012a1:	5d                   	pop    %ebp
f01012a2:	c3                   	ret    

f01012a3 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012a3:	c1 e8 0c             	shr    $0xc,%eax
f01012a6:	3b 05 84 6f 18 f0    	cmp    0xf0186f84,%eax
f01012ac:	72 22                	jb     f01012d0 <pa2page+0x2d>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f01012ae:	55                   	push   %ebp
f01012af:	89 e5                	mov    %esp,%ebp
f01012b1:	83 ec 18             	sub    $0x18,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f01012b4:	c7 44 24 08 74 54 10 	movl   $0xf0105474,0x8(%esp)
f01012bb:	f0 
f01012bc:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01012c3:	00 
f01012c4:	c7 04 24 ed 59 10 f0 	movl   $0xf01059ed,(%esp)
f01012cb:	e8 f6 ed ff ff       	call   f01000c6 <_panic>
	return &pages[PGNUM(pa)];
f01012d0:	8b 15 8c 6f 18 f0    	mov    0xf0186f8c,%edx
f01012d6:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01012d9:	c3                   	ret    

f01012da <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01012da:	55                   	push   %ebp
f01012db:	89 e5                	mov    %esp,%ebp
f01012dd:	56                   	push   %esi
f01012de:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f01012df:	b8 00 00 00 00       	mov    $0x0,%eax
f01012e4:	e8 81 f9 ff ff       	call   f0100c6a <boot_alloc>
f01012e9:	89 c1                	mov    %eax,%ecx
f01012eb:	ba 19 01 00 00       	mov    $0x119,%edx
f01012f0:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f01012f5:	e8 43 f9 ff ff       	call   f0100c3d <_paddr>
f01012fa:	c1 e8 0c             	shr    $0xc,%eax
f01012fd:	8b 35 bc 52 18 f0    	mov    0xf01852bc,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101303:	ba 01 00 00 00       	mov    $0x1,%edx
f0101308:	eb 2e                	jmp    f0101338 <page_init+0x5e>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f010130a:	39 c2                	cmp    %eax,%edx
f010130c:	73 08                	jae    f0101316 <page_init+0x3c>
f010130e:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101314:	77 1f                	ja     f0101335 <page_init+0x5b>
f0101316:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
		pages[i].pp_ref = 0;
f010131d:	89 cb                	mov    %ecx,%ebx
f010131f:	03 1d 8c 6f 18 f0    	add    0xf0186f8c,%ebx
f0101325:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f010132b:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f010132d:	89 ce                	mov    %ecx,%esi
f010132f:	03 35 8c 6f 18 f0    	add    0xf0186f8c,%esi
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101335:	83 c2 01             	add    $0x1,%edx
f0101338:	3b 15 84 6f 18 f0    	cmp    0xf0186f84,%edx
f010133e:	72 ca                	jb     f010130a <page_init+0x30>
f0101340:	89 35 bc 52 18 f0    	mov    %esi,0xf01852bc
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101346:	5b                   	pop    %ebx
f0101347:	5e                   	pop    %esi
f0101348:	5d                   	pop    %ebp
f0101349:	c3                   	ret    

f010134a <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	53                   	push   %ebx
f010134e:	83 ec 14             	sub    $0x14,%esp
f0101351:	8b 1d bc 52 18 f0    	mov    0xf01852bc,%ebx
f0101357:	85 db                	test   %ebx,%ebx
f0101359:	74 36                	je     f0101391 <page_alloc+0x47>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f010135b:	8b 03                	mov    (%ebx),%eax
f010135d:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc
	pag->pp_link = NULL;
f0101362:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
	return pag;
f0101368:	89 d8                	mov    %ebx,%eax
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
	pag->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f010136a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010136e:	74 26                	je     f0101396 <page_alloc+0x4c>
f0101370:	e8 3e f8 ff ff       	call   f0100bb3 <page2kva>
f0101375:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010137c:	00 
f010137d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101384:	00 
f0101385:	89 04 24             	mov    %eax,(%esp)
f0101388:	e8 9a 34 00 00       	call   f0104827 <memset>
	return pag;
f010138d:	89 d8                	mov    %ebx,%eax
f010138f:	eb 05                	jmp    f0101396 <page_alloc+0x4c>
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f0101391:	b8 00 00 00 00       	mov    $0x0,%eax
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
	pag->pp_link = NULL;
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
	return pag;
}
f0101396:	83 c4 14             	add    $0x14,%esp
f0101399:	5b                   	pop    %ebx
f010139a:	5d                   	pop    %ebp
f010139b:	c3                   	ret    

f010139c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010139c:	55                   	push   %ebp
f010139d:	89 e5                	mov    %esp,%ebp
f010139f:	83 ec 18             	sub    $0x18,%esp
f01013a2:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f01013a5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01013aa:	74 1c                	je     f01013c8 <page_free+0x2c>
f01013ac:	c7 44 24 08 e6 5a 10 	movl   $0xf0105ae6,0x8(%esp)
f01013b3:	f0 
f01013b4:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
f01013bb:	00 
f01013bc:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01013c3:	e8 fe ec ff ff       	call   f01000c6 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f01013c8:	83 38 00             	cmpl   $0x0,(%eax)
f01013cb:	74 1c                	je     f01013e9 <page_free+0x4d>
f01013cd:	c7 44 24 08 94 54 10 	movl   $0xf0105494,0x8(%esp)
f01013d4:	f0 
f01013d5:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01013dc:	00 
f01013dd:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01013e4:	e8 dd ec ff ff       	call   f01000c6 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01013e9:	8b 15 bc 52 18 f0    	mov    0xf01852bc,%edx
f01013ef:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01013f1:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc
}
f01013f6:	c9                   	leave  
f01013f7:	c3                   	ret    

f01013f8 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f01013f8:	55                   	push   %ebp
f01013f9:	89 e5                	mov    %esp,%ebp
f01013fb:	57                   	push   %edi
f01013fc:	56                   	push   %esi
f01013fd:	53                   	push   %ebx
f01013fe:	83 ec 2c             	sub    $0x2c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101401:	83 3d 8c 6f 18 f0 00 	cmpl   $0x0,0xf0186f8c
f0101408:	75 1c                	jne    f0101426 <check_page_alloc+0x2e>
		panic("'pages' is a null pointer!");
f010140a:	c7 44 24 08 fa 5a 10 	movl   $0xf0105afa,0x8(%esp)
f0101411:	f0 
f0101412:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0101419:	00 
f010141a:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101421:	e8 a0 ec ff ff       	call   f01000c6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101426:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f010142b:	be 00 00 00 00       	mov    $0x0,%esi
f0101430:	eb 05                	jmp    f0101437 <check_page_alloc+0x3f>
		++nfree;
f0101432:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101435:	8b 00                	mov    (%eax),%eax
f0101437:	85 c0                	test   %eax,%eax
f0101439:	75 f7                	jne    f0101432 <check_page_alloc+0x3a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010143b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101442:	e8 03 ff ff ff       	call   f010134a <page_alloc>
f0101447:	89 c7                	mov    %eax,%edi
f0101449:	85 c0                	test   %eax,%eax
f010144b:	75 24                	jne    f0101471 <check_page_alloc+0x79>
f010144d:	c7 44 24 0c 15 5b 10 	movl   $0xf0105b15,0xc(%esp)
f0101454:	f0 
f0101455:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010145c:	f0 
f010145d:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0101464:	00 
f0101465:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010146c:	e8 55 ec ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101471:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101478:	e8 cd fe ff ff       	call   f010134a <page_alloc>
f010147d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101480:	85 c0                	test   %eax,%eax
f0101482:	75 24                	jne    f01014a8 <check_page_alloc+0xb0>
f0101484:	c7 44 24 0c 2b 5b 10 	movl   $0xf0105b2b,0xc(%esp)
f010148b:	f0 
f010148c:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101493:	f0 
f0101494:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f010149b:	00 
f010149c:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01014a3:	e8 1e ec ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014af:	e8 96 fe ff ff       	call   f010134a <page_alloc>
f01014b4:	89 c3                	mov    %eax,%ebx
f01014b6:	85 c0                	test   %eax,%eax
f01014b8:	75 24                	jne    f01014de <check_page_alloc+0xe6>
f01014ba:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f01014c1:	f0 
f01014c2:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01014c9:	f0 
f01014ca:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01014d1:	00 
f01014d2:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01014d9:	e8 e8 eb ff ff       	call   f01000c6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014de:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01014e1:	75 24                	jne    f0101507 <check_page_alloc+0x10f>
f01014e3:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f01014ea:	f0 
f01014eb:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01014f2:	f0 
f01014f3:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01014fa:	00 
f01014fb:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101502:	e8 bf eb ff ff       	call   f01000c6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101507:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010150a:	74 04                	je     f0101510 <check_page_alloc+0x118>
f010150c:	39 f8                	cmp    %edi,%eax
f010150e:	75 24                	jne    f0101534 <check_page_alloc+0x13c>
f0101510:	c7 44 24 0c c0 54 10 	movl   $0xf01054c0,0xc(%esp)
f0101517:	f0 
f0101518:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010151f:	f0 
f0101520:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0101527:	00 
f0101528:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010152f:	e8 92 eb ff ff       	call   f01000c6 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101534:	89 f8                	mov    %edi,%eax
f0101536:	e8 88 f5 ff ff       	call   f0100ac3 <page2pa>
f010153b:	8b 0d 84 6f 18 f0    	mov    0xf0186f84,%ecx
f0101541:	c1 e1 0c             	shl    $0xc,%ecx
f0101544:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101547:	39 c8                	cmp    %ecx,%eax
f0101549:	72 24                	jb     f010156f <check_page_alloc+0x177>
f010154b:	c7 44 24 0c 69 5b 10 	movl   $0xf0105b69,0xc(%esp)
f0101552:	f0 
f0101553:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010155a:	f0 
f010155b:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101562:	00 
f0101563:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010156a:	e8 57 eb ff ff       	call   f01000c6 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010156f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101572:	e8 4c f5 ff ff       	call   f0100ac3 <page2pa>
f0101577:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010157a:	77 24                	ja     f01015a0 <check_page_alloc+0x1a8>
f010157c:	c7 44 24 0c 86 5b 10 	movl   $0xf0105b86,0xc(%esp)
f0101583:	f0 
f0101584:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010158b:	f0 
f010158c:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101593:	00 
f0101594:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010159b:	e8 26 eb ff ff       	call   f01000c6 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015a0:	89 d8                	mov    %ebx,%eax
f01015a2:	e8 1c f5 ff ff       	call   f0100ac3 <page2pa>
f01015a7:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01015aa:	77 24                	ja     f01015d0 <check_page_alloc+0x1d8>
f01015ac:	c7 44 24 0c a3 5b 10 	movl   $0xf0105ba3,0xc(%esp)
f01015b3:	f0 
f01015b4:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01015bb:	f0 
f01015bc:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f01015c3:	00 
f01015c4:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01015cb:	e8 f6 ea ff ff       	call   f01000c6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015d0:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f01015d5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01015d8:	c7 05 bc 52 18 f0 00 	movl   $0x0,0xf01852bc
f01015df:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e9:	e8 5c fd ff ff       	call   f010134a <page_alloc>
f01015ee:	85 c0                	test   %eax,%eax
f01015f0:	74 24                	je     f0101616 <check_page_alloc+0x21e>
f01015f2:	c7 44 24 0c c0 5b 10 	movl   $0xf0105bc0,0xc(%esp)
f01015f9:	f0 
f01015fa:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101601:	f0 
f0101602:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0101609:	00 
f010160a:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101611:	e8 b0 ea ff ff       	call   f01000c6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101616:	89 3c 24             	mov    %edi,(%esp)
f0101619:	e8 7e fd ff ff       	call   f010139c <page_free>
	page_free(pp1);
f010161e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101621:	89 04 24             	mov    %eax,(%esp)
f0101624:	e8 73 fd ff ff       	call   f010139c <page_free>
	page_free(pp2);
f0101629:	89 1c 24             	mov    %ebx,(%esp)
f010162c:	e8 6b fd ff ff       	call   f010139c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101631:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101638:	e8 0d fd ff ff       	call   f010134a <page_alloc>
f010163d:	89 c3                	mov    %eax,%ebx
f010163f:	85 c0                	test   %eax,%eax
f0101641:	75 24                	jne    f0101667 <check_page_alloc+0x26f>
f0101643:	c7 44 24 0c 15 5b 10 	movl   $0xf0105b15,0xc(%esp)
f010164a:	f0 
f010164b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101652:	f0 
f0101653:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f010165a:	00 
f010165b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101662:	e8 5f ea ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101667:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010166e:	e8 d7 fc ff ff       	call   f010134a <page_alloc>
f0101673:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101676:	85 c0                	test   %eax,%eax
f0101678:	75 24                	jne    f010169e <check_page_alloc+0x2a6>
f010167a:	c7 44 24 0c 2b 5b 10 	movl   $0xf0105b2b,0xc(%esp)
f0101681:	f0 
f0101682:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101689:	f0 
f010168a:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0101691:	00 
f0101692:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101699:	e8 28 ea ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f010169e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a5:	e8 a0 fc ff ff       	call   f010134a <page_alloc>
f01016aa:	89 c7                	mov    %eax,%edi
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	75 24                	jne    f01016d4 <check_page_alloc+0x2dc>
f01016b0:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f01016b7:	f0 
f01016b8:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01016bf:	f0 
f01016c0:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f01016c7:	00 
f01016c8:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01016cf:	e8 f2 e9 ff ff       	call   f01000c6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016d4:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01016d7:	75 24                	jne    f01016fd <check_page_alloc+0x305>
f01016d9:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f01016e0:	f0 
f01016e1:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01016e8:	f0 
f01016e9:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f01016f0:	00 
f01016f1:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01016f8:	e8 c9 e9 ff ff       	call   f01000c6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016fd:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101700:	74 04                	je     f0101706 <check_page_alloc+0x30e>
f0101702:	39 d8                	cmp    %ebx,%eax
f0101704:	75 24                	jne    f010172a <check_page_alloc+0x332>
f0101706:	c7 44 24 0c c0 54 10 	movl   $0xf01054c0,0xc(%esp)
f010170d:	f0 
f010170e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101715:	f0 
f0101716:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f010171d:	00 
f010171e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101725:	e8 9c e9 ff ff       	call   f01000c6 <_panic>
	assert(!page_alloc(0));
f010172a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101731:	e8 14 fc ff ff       	call   f010134a <page_alloc>
f0101736:	85 c0                	test   %eax,%eax
f0101738:	74 24                	je     f010175e <check_page_alloc+0x366>
f010173a:	c7 44 24 0c c0 5b 10 	movl   $0xf0105bc0,0xc(%esp)
f0101741:	f0 
f0101742:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101749:	f0 
f010174a:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0101751:	00 
f0101752:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101759:	e8 68 e9 ff ff       	call   f01000c6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010175e:	89 d8                	mov    %ebx,%eax
f0101760:	e8 4e f4 ff ff       	call   f0100bb3 <page2kva>
f0101765:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010176c:	00 
f010176d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101774:	00 
f0101775:	89 04 24             	mov    %eax,(%esp)
f0101778:	e8 aa 30 00 00       	call   f0104827 <memset>
	page_free(pp0);
f010177d:	89 1c 24             	mov    %ebx,(%esp)
f0101780:	e8 17 fc ff ff       	call   f010139c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101785:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010178c:	e8 b9 fb ff ff       	call   f010134a <page_alloc>
f0101791:	85 c0                	test   %eax,%eax
f0101793:	75 24                	jne    f01017b9 <check_page_alloc+0x3c1>
f0101795:	c7 44 24 0c cf 5b 10 	movl   $0xf0105bcf,0xc(%esp)
f010179c:	f0 
f010179d:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01017a4:	f0 
f01017a5:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f01017ac:	00 
f01017ad:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01017b4:	e8 0d e9 ff ff       	call   f01000c6 <_panic>
	assert(pp && pp0 == pp);
f01017b9:	39 c3                	cmp    %eax,%ebx
f01017bb:	74 24                	je     f01017e1 <check_page_alloc+0x3e9>
f01017bd:	c7 44 24 0c ed 5b 10 	movl   $0xf0105bed,0xc(%esp)
f01017c4:	f0 
f01017c5:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01017cc:	f0 
f01017cd:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f01017d4:	00 
f01017d5:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01017dc:	e8 e5 e8 ff ff       	call   f01000c6 <_panic>
	c = page2kva(pp);
f01017e1:	89 d8                	mov    %ebx,%eax
f01017e3:	e8 cb f3 ff ff       	call   f0100bb3 <page2kva>
	for (i = 0; i < PGSIZE; i++)
f01017e8:	ba 00 00 00 00       	mov    $0x0,%edx
		assert(c[i] == 0);
f01017ed:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01017f1:	74 24                	je     f0101817 <check_page_alloc+0x41f>
f01017f3:	c7 44 24 0c fd 5b 10 	movl   $0xf0105bfd,0xc(%esp)
f01017fa:	f0 
f01017fb:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101802:	f0 
f0101803:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f010180a:	00 
f010180b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101812:	e8 af e8 ff ff       	call   f01000c6 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101817:	83 c2 01             	add    $0x1,%edx
f010181a:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f0101820:	75 cb                	jne    f01017ed <check_page_alloc+0x3f5>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101822:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101825:	a3 bc 52 18 f0       	mov    %eax,0xf01852bc

	// free the pages we took
	page_free(pp0);
f010182a:	89 1c 24             	mov    %ebx,(%esp)
f010182d:	e8 6a fb ff ff       	call   f010139c <page_free>
	page_free(pp1);
f0101832:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101835:	89 04 24             	mov    %eax,(%esp)
f0101838:	e8 5f fb ff ff       	call   f010139c <page_free>
	page_free(pp2);
f010183d:	89 3c 24             	mov    %edi,(%esp)
f0101840:	e8 57 fb ff ff       	call   f010139c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101845:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f010184a:	eb 05                	jmp    f0101851 <check_page_alloc+0x459>
		--nfree;
f010184c:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010184f:	8b 00                	mov    (%eax),%eax
f0101851:	85 c0                	test   %eax,%eax
f0101853:	75 f7                	jne    f010184c <check_page_alloc+0x454>
		--nfree;
	assert(nfree == 0);
f0101855:	85 f6                	test   %esi,%esi
f0101857:	74 24                	je     f010187d <check_page_alloc+0x485>
f0101859:	c7 44 24 0c 07 5c 10 	movl   $0xf0105c07,0xc(%esp)
f0101860:	f0 
f0101861:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101868:	f0 
f0101869:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101870:	00 
f0101871:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101878:	e8 49 e8 ff ff       	call   f01000c6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010187d:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f0101884:	e8 d9 1f 00 00       	call   f0103862 <cprintf>
}
f0101889:	83 c4 2c             	add    $0x2c,%esp
f010188c:	5b                   	pop    %ebx
f010188d:	5e                   	pop    %esi
f010188e:	5f                   	pop    %edi
f010188f:	5d                   	pop    %ebp
f0101890:	c3                   	ret    

f0101891 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101891:	55                   	push   %ebp
f0101892:	89 e5                	mov    %esp,%ebp
f0101894:	83 ec 18             	sub    $0x18,%esp
f0101897:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010189a:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f010189e:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01018a1:	66 89 50 04          	mov    %dx,0x4(%eax)
f01018a5:	66 85 d2             	test   %dx,%dx
f01018a8:	75 08                	jne    f01018b2 <page_decref+0x21>
		page_free(pp);
f01018aa:	89 04 24             	mov    %eax,(%esp)
f01018ad:	e8 ea fa ff ff       	call   f010139c <page_free>
}
f01018b2:	c9                   	leave  
f01018b3:	c3                   	ret    

f01018b4 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01018b4:	55                   	push   %ebp
f01018b5:	89 e5                	mov    %esp,%ebp
f01018b7:	57                   	push   %edi
f01018b8:	56                   	push   %esi
f01018b9:	53                   	push   %ebx
f01018ba:	83 ec 1c             	sub    $0x1c,%esp
f01018bd:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f01018c0:	89 f7                	mov    %esi,%edi
f01018c2:	c1 ef 16             	shr    $0x16,%edi
f01018c5:	c1 e7 02             	shl    $0x2,%edi
f01018c8:	03 7d 08             	add    0x8(%ebp),%edi
f01018cb:	8b 1f                	mov    (%edi),%ebx
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f01018cd:	89 d9                	mov    %ebx,%ecx
f01018cf:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01018d5:	ba 6e 01 00 00       	mov    $0x16e,%edx
f01018da:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f01018df:	e8 97 f2 ff ff       	call   f0100b7b <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f01018e4:	f6 c3 01             	test   $0x1,%bl
f01018e7:	74 0d                	je     f01018f6 <pgdir_walk+0x42>
f01018e9:	c1 ee 0a             	shr    $0xa,%esi
f01018ec:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01018f2:	01 f0                	add    %esi,%eax
f01018f4:	eb 51                	jmp    f0101947 <pgdir_walk+0x93>

	if (!create) return NULL;
f01018f6:	b8 00 00 00 00       	mov    $0x0,%eax
f01018fb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01018ff:	74 46                	je     f0101947 <pgdir_walk+0x93>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0101901:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101908:	e8 3d fa ff ff       	call   f010134a <page_alloc>
f010190d:	89 c3                	mov    %eax,%ebx
	if (page==NULL) return NULL;
f010190f:	85 c0                	test   %eax,%eax
f0101911:	74 2f                	je     f0101942 <pgdir_walk+0x8e>
	physaddr_t pt_start = page2pa(page);
f0101913:	e8 ab f1 ff ff       	call   f0100ac3 <page2pa>
	page->pp_ref ++;
f0101918:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f010191d:	89 c2                	mov    %eax,%edx
f010191f:	83 ca 07             	or     $0x7,%edx
f0101922:	89 17                	mov    %edx,(%edi)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f0101924:	89 c1                	mov    %eax,%ecx
f0101926:	ba 78 01 00 00       	mov    $0x178,%edx
f010192b:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0101930:	e8 46 f2 ff ff       	call   f0100b7b <_kaddr>
f0101935:	c1 ee 0a             	shr    $0xa,%esi
f0101938:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010193e:	01 f0                	add    %esi,%eax
f0101940:	eb 05                	jmp    f0101947 <pgdir_walk+0x93>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f0101942:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f0101947:	83 c4 1c             	add    $0x1c,%esp
f010194a:	5b                   	pop    %ebx
f010194b:	5e                   	pop    %esi
f010194c:	5f                   	pop    %edi
f010194d:	5d                   	pop    %ebp
f010194e:	c3                   	ret    

f010194f <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk
//#define TP1_PSE 1
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010194f:	55                   	push   %ebp
f0101950:	89 e5                	mov    %esp,%ebp
f0101952:	57                   	push   %edi
f0101953:	56                   	push   %esi
f0101954:	53                   	push   %ebx
f0101955:	83 ec 2c             	sub    $0x2c,%esp
f0101958:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010195b:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(va % PGSIZE == 0);
f010195e:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0101964:	74 24                	je     f010198a <boot_map_region+0x3b>
f0101966:	c7 44 24 0c 12 5c 10 	movl   $0xf0105c12,0xc(%esp)
f010196d:	f0 
f010196e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101975:	f0 
f0101976:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010197d:	00 
f010197e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101985:	e8 3c e7 ff ff       	call   f01000c6 <_panic>
f010198a:	89 ce                	mov    %ecx,%esi
	assert(pa % PGSIZE == 0);
f010198c:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101991:	74 24                	je     f01019b7 <boot_map_region+0x68>
f0101993:	c7 44 24 0c 23 5c 10 	movl   $0xf0105c23,0xc(%esp)
f010199a:	f0 
f010199b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01019a2:	f0 
f01019a3:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f01019aa:	00 
f01019ab:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01019b2:	e8 0f e7 ff ff       	call   f01000c6 <_panic>
	assert(size % PGSIZE == 0);	
f01019b7:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01019bd:	75 12                	jne    f01019d1 <boot_map_region+0x82>
f01019bf:	89 d3                	mov    %edx,%ebx
f01019c1:	29 d0                	sub    %edx,%eax
f01019c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
			*pte_addr = pa | perm | PTE_P;
f01019c6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01019c9:	83 c8 01             	or     $0x1,%eax
f01019cc:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01019cf:	eb 4c                	jmp    f0101a1d <boot_map_region+0xce>
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	assert(va % PGSIZE == 0);
	assert(pa % PGSIZE == 0);
	assert(size % PGSIZE == 0);	
f01019d1:	c7 44 24 0c 34 5c 10 	movl   $0xf0105c34,0xc(%esp)
f01019d8:	f0 
f01019d9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01019e0:	f0 
f01019e1:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
f01019e8:	00 
f01019e9:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01019f0:	e8 d1 e6 ff ff       	call   f01000c6 <_panic>
	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
f01019f5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01019fc:	00 
f01019fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a01:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a04:	89 04 24             	mov    %eax,(%esp)
f0101a07:	e8 a8 fe ff ff       	call   f01018b4 <pgdir_walk>
			*pte_addr = pa | perm | PTE_P;
f0101a0c:	0b 7d dc             	or     -0x24(%ebp),%edi
f0101a0f:	89 38                	mov    %edi,(%eax)
			size-=PGSIZE;		
f0101a11:	81 ee 00 10 00 00    	sub    $0x1000,%esi
			//incremento
			va+=PGSIZE;
f0101a17:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101a1d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101a20:	8d 3c 18             	lea    (%eax,%ebx,1),%edi

	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
f0101a23:	85 f6                	test   %esi,%esi
f0101a25:	75 ce                	jne    f01019f5 <boot_map_region+0xa6>
				va+=PGSIZE;
				pa+=PGSIZE;
			}
		}
	#endif
}
f0101a27:	83 c4 2c             	add    $0x2c,%esp
f0101a2a:	5b                   	pop    %ebx
f0101a2b:	5e                   	pop    %esi
f0101a2c:	5f                   	pop    %edi
f0101a2d:	5d                   	pop    %ebp
f0101a2e:	c3                   	ret    

f0101a2f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101a2f:	55                   	push   %ebp
f0101a30:	89 e5                	mov    %esp,%ebp
f0101a32:	53                   	push   %ebx
f0101a33:	83 ec 14             	sub    $0x14,%esp
f0101a36:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f0101a39:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a40:	00 
f0101a41:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a48:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a4b:	89 04 24             	mov    %eax,(%esp)
f0101a4e:	e8 61 fe ff ff       	call   f01018b4 <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f0101a53:	85 db                	test   %ebx,%ebx
f0101a55:	74 02                	je     f0101a59 <page_lookup+0x2a>
f0101a57:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101a59:	85 c0                	test   %eax,%eax
f0101a5b:	74 1a                	je     f0101a77 <page_lookup+0x48>
	if (!(*pte_addr & PTE_P)) return NULL;
f0101a5d:	8b 10                	mov    (%eax),%edx
f0101a5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a64:	f6 c2 01             	test   $0x1,%dl
f0101a67:	74 13                	je     f0101a7c <page_lookup+0x4d>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
f0101a69:	89 d0                	mov    %edx,%eax
f0101a6b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	return pa2page(pageaddr);
f0101a70:	e8 2e f8 ff ff       	call   f01012a3 <pa2page>
f0101a75:	eb 05                	jmp    f0101a7c <page_lookup+0x4d>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f0101a77:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f0101a7c:	83 c4 14             	add    $0x14,%esp
f0101a7f:	5b                   	pop    %ebx
f0101a80:	5d                   	pop    %ebp
f0101a81:	c3                   	ret    

f0101a82 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101a82:	55                   	push   %ebp
f0101a83:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f0101a85:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a88:	e8 16 f0 ff ff       	call   f0100aa3 <invlpg>
}
f0101a8d:	5d                   	pop    %ebp
f0101a8e:	c3                   	ret    

f0101a8f <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101a8f:	55                   	push   %ebp
f0101a90:	89 e5                	mov    %esp,%ebp
f0101a92:	56                   	push   %esi
f0101a93:	53                   	push   %ebx
f0101a94:	83 ec 20             	sub    $0x20,%esp
f0101a97:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101a9a:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f0101a9d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101aa0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101aa4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101aa8:	89 1c 24             	mov    %ebx,(%esp)
f0101aab:	e8 7f ff ff ff       	call   f0101a2f <page_lookup>
	if (!page_ptr) return;
f0101ab0:	85 c0                	test   %eax,%eax
f0101ab2:	74 1d                	je     f0101ad1 <page_remove+0x42>
	page_decref(page_ptr);
f0101ab4:	89 04 24             	mov    %eax,(%esp)
f0101ab7:	e8 d5 fd ff ff       	call   f0101891 <page_decref>
	*pte_addr = 0;
f0101abc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101abf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f0101ac5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ac9:	89 1c 24             	mov    %ebx,(%esp)
f0101acc:	e8 b1 ff ff ff       	call   f0101a82 <tlb_invalidate>
}
f0101ad1:	83 c4 20             	add    $0x20,%esp
f0101ad4:	5b                   	pop    %ebx
f0101ad5:	5e                   	pop    %esi
f0101ad6:	5d                   	pop    %ebp
f0101ad7:	c3                   	ret    

f0101ad8 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101ad8:	55                   	push   %ebp
f0101ad9:	89 e5                	mov    %esp,%ebp
f0101adb:	57                   	push   %edi
f0101adc:	56                   	push   %esi
f0101add:	53                   	push   %ebx
f0101ade:	83 ec 1c             	sub    $0x1c,%esp
f0101ae1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101ae4:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101ae7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101aee:	00 
f0101aef:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101af3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101af6:	89 04 24             	mov    %eax,(%esp)
f0101af9:	e8 b6 fd ff ff       	call   f01018b4 <pgdir_walk>
f0101afe:	89 c3                	mov    %eax,%ebx
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101b00:	85 c0                	test   %eax,%eax
f0101b02:	74 31                	je     f0101b35 <page_insert+0x5d>
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f0101b04:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f0101b09:	f6 00 01             	testb  $0x1,(%eax)
f0101b0c:	74 0f                	je     f0101b1d <page_insert+0x45>
f0101b0e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101b12:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b15:	89 04 24             	mov    %eax,(%esp)
f0101b18:	e8 72 ff ff ff       	call   f0101a8f <page_remove>
	*pte_addr = page2pa(pp) | perm | PTE_P;
f0101b1d:	89 f0                	mov    %esi,%eax
f0101b1f:	e8 9f ef ff ff       	call   f0100ac3 <page2pa>
f0101b24:	8b 55 14             	mov    0x14(%ebp),%edx
f0101b27:	83 ca 01             	or     $0x1,%edx
f0101b2a:	09 d0                	or     %edx,%eax
f0101b2c:	89 03                	mov    %eax,(%ebx)
	return 0;
f0101b2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b33:	eb 05                	jmp    f0101b3a <page_insert+0x62>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101b35:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101b3a:	83 c4 1c             	add    $0x1c,%esp
f0101b3d:	5b                   	pop    %ebx
f0101b3e:	5e                   	pop    %esi
f0101b3f:	5f                   	pop    %edi
f0101b40:	5d                   	pop    %ebp
f0101b41:	c3                   	ret    

f0101b42 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101b42:	55                   	push   %ebp
f0101b43:	89 e5                	mov    %esp,%ebp
f0101b45:	57                   	push   %edi
f0101b46:	56                   	push   %esi
f0101b47:	53                   	push   %ebx
f0101b48:	83 ec 3c             	sub    $0x3c,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b4b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b52:	e8 f3 f7 ff ff       	call   f010134a <page_alloc>
f0101b57:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b5a:	85 c0                	test   %eax,%eax
f0101b5c:	75 24                	jne    f0101b82 <check_page+0x40>
f0101b5e:	c7 44 24 0c 15 5b 10 	movl   $0xf0105b15,0xc(%esp)
f0101b65:	f0 
f0101b66:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101b6d:	f0 
f0101b6e:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101b75:	00 
f0101b76:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101b7d:	e8 44 e5 ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b82:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b89:	e8 bc f7 ff ff       	call   f010134a <page_alloc>
f0101b8e:	89 c3                	mov    %eax,%ebx
f0101b90:	85 c0                	test   %eax,%eax
f0101b92:	75 24                	jne    f0101bb8 <check_page+0x76>
f0101b94:	c7 44 24 0c 2b 5b 10 	movl   $0xf0105b2b,0xc(%esp)
f0101b9b:	f0 
f0101b9c:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101bab:	00 
f0101bac:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101bb3:	e8 0e e5 ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bb8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bbf:	e8 86 f7 ff ff       	call   f010134a <page_alloc>
f0101bc4:	89 c6                	mov    %eax,%esi
f0101bc6:	85 c0                	test   %eax,%eax
f0101bc8:	75 24                	jne    f0101bee <check_page+0xac>
f0101bca:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f0101bd1:	f0 
f0101bd2:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101bd9:	f0 
f0101bda:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101be1:	00 
f0101be2:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101be9:	e8 d8 e4 ff ff       	call   f01000c6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bee:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101bf1:	75 24                	jne    f0101c17 <check_page+0xd5>
f0101bf3:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f0101bfa:	f0 
f0101bfb:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101c02:	f0 
f0101c03:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101c0a:	00 
f0101c0b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101c12:	e8 af e4 ff ff       	call   f01000c6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c17:	39 c3                	cmp    %eax,%ebx
f0101c19:	74 05                	je     f0101c20 <check_page+0xde>
f0101c1b:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
f0101c1e:	75 24                	jne    f0101c44 <check_page+0x102>
f0101c20:	c7 44 24 0c c0 54 10 	movl   $0xf01054c0,0xc(%esp)
f0101c27:	f0 
f0101c28:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101c2f:	f0 
f0101c30:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101c37:	00 
f0101c38:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101c3f:	e8 82 e4 ff ff       	call   f01000c6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c44:	a1 bc 52 18 f0       	mov    0xf01852bc,%eax
f0101c49:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101c4c:	c7 05 bc 52 18 f0 00 	movl   $0x0,0xf01852bc
f0101c53:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c5d:	e8 e8 f6 ff ff       	call   f010134a <page_alloc>
f0101c62:	85 c0                	test   %eax,%eax
f0101c64:	74 24                	je     f0101c8a <check_page+0x148>
f0101c66:	c7 44 24 0c c0 5b 10 	movl   $0xf0105bc0,0xc(%esp)
f0101c6d:	f0 
f0101c6e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101c75:	f0 
f0101c76:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101c7d:	00 
f0101c7e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101c85:	e8 3c e4 ff ff       	call   f01000c6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c8a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c8d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c91:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c98:	00 
f0101c99:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101c9e:	89 04 24             	mov    %eax,(%esp)
f0101ca1:	e8 89 fd ff ff       	call   f0101a2f <page_lookup>
f0101ca6:	85 c0                	test   %eax,%eax
f0101ca8:	74 24                	je     f0101cce <check_page+0x18c>
f0101caa:	c7 44 24 0c 00 55 10 	movl   $0xf0105500,0xc(%esp)
f0101cb1:	f0 
f0101cb2:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101cb9:	f0 
f0101cba:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101cc1:	00 
f0101cc2:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101cc9:	e8 f8 e3 ff ff       	call   f01000c6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101cce:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cd5:	00 
f0101cd6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cdd:	00 
f0101cde:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ce2:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101ce7:	89 04 24             	mov    %eax,(%esp)
f0101cea:	e8 e9 fd ff ff       	call   f0101ad8 <page_insert>
f0101cef:	85 c0                	test   %eax,%eax
f0101cf1:	78 24                	js     f0101d17 <check_page+0x1d5>
f0101cf3:	c7 44 24 0c 38 55 10 	movl   $0xf0105538,0xc(%esp)
f0101cfa:	f0 
f0101cfb:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101d02:	f0 
f0101d03:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101d0a:	00 
f0101d0b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101d12:	e8 af e3 ff ff       	call   f01000c6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101d17:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d1a:	89 04 24             	mov    %eax,(%esp)
f0101d1d:	e8 7a f6 ff ff       	call   f010139c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101d22:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d29:	00 
f0101d2a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d31:	00 
f0101d32:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d36:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101d3b:	89 04 24             	mov    %eax,(%esp)
f0101d3e:	e8 95 fd ff ff       	call   f0101ad8 <page_insert>
f0101d43:	85 c0                	test   %eax,%eax
f0101d45:	74 24                	je     f0101d6b <check_page+0x229>
f0101d47:	c7 44 24 0c 68 55 10 	movl   $0xf0105568,0xc(%esp)
f0101d4e:	f0 
f0101d4f:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101d56:	f0 
f0101d57:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101d5e:	00 
f0101d5f:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101d66:	e8 5b e3 ff ff       	call   f01000c6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d6b:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0101d71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d74:	e8 4a ed ff ff       	call   f0100ac3 <page2pa>
f0101d79:	8b 17                	mov    (%edi),%edx
f0101d7b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d81:	39 c2                	cmp    %eax,%edx
f0101d83:	74 24                	je     f0101da9 <check_page+0x267>
f0101d85:	c7 44 24 0c 98 55 10 	movl   $0xf0105598,0xc(%esp)
f0101d8c:	f0 
f0101d8d:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101d9c:	00 
f0101d9d:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101da4:	e8 1d e3 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101da9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101dae:	89 f8                	mov    %edi,%eax
f0101db0:	e8 1c ee ff ff       	call   f0100bd1 <check_va2pa>
f0101db5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101db8:	89 d8                	mov    %ebx,%eax
f0101dba:	e8 04 ed ff ff       	call   f0100ac3 <page2pa>
f0101dbf:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101dc2:	74 24                	je     f0101de8 <check_page+0x2a6>
f0101dc4:	c7 44 24 0c c0 55 10 	movl   $0xf01055c0,0xc(%esp)
f0101dcb:	f0 
f0101dcc:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101dd3:	f0 
f0101dd4:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101ddb:	00 
f0101ddc:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101de3:	e8 de e2 ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 1);
f0101de8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ded:	74 24                	je     f0101e13 <check_page+0x2d1>
f0101def:	c7 44 24 0c 47 5c 10 	movl   $0xf0105c47,0xc(%esp)
f0101df6:	f0 
f0101df7:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101dfe:	f0 
f0101dff:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101e06:	00 
f0101e07:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101e0e:	e8 b3 e2 ff ff       	call   f01000c6 <_panic>
	assert(pp0->pp_ref == 1);
f0101e13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e16:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e1b:	74 24                	je     f0101e41 <check_page+0x2ff>
f0101e1d:	c7 44 24 0c 58 5c 10 	movl   $0xf0105c58,0xc(%esp)
f0101e24:	f0 
f0101e25:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101e2c:	f0 
f0101e2d:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101e34:	00 
f0101e35:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101e3c:	e8 85 e2 ff ff       	call   f01000c6 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e41:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e48:	00 
f0101e49:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e50:	00 
f0101e51:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101e55:	89 3c 24             	mov    %edi,(%esp)
f0101e58:	e8 7b fc ff ff       	call   f0101ad8 <page_insert>
f0101e5d:	85 c0                	test   %eax,%eax
f0101e5f:	74 24                	je     f0101e85 <check_page+0x343>
f0101e61:	c7 44 24 0c f0 55 10 	movl   $0xf01055f0,0xc(%esp)
f0101e68:	f0 
f0101e69:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101e70:	f0 
f0101e71:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101e78:	00 
f0101e79:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101e80:	e8 41 e2 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e85:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e8a:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101e8f:	e8 3d ed ff ff       	call   f0100bd1 <check_va2pa>
f0101e94:	89 c7                	mov    %eax,%edi
f0101e96:	89 f0                	mov    %esi,%eax
f0101e98:	e8 26 ec ff ff       	call   f0100ac3 <page2pa>
f0101e9d:	39 c7                	cmp    %eax,%edi
f0101e9f:	74 24                	je     f0101ec5 <check_page+0x383>
f0101ea1:	c7 44 24 0c 2c 56 10 	movl   $0xf010562c,0xc(%esp)
f0101ea8:	f0 
f0101ea9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101eb0:	f0 
f0101eb1:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101eb8:	00 
f0101eb9:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101ec0:	e8 01 e2 ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ec5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101eca:	74 24                	je     f0101ef0 <check_page+0x3ae>
f0101ecc:	c7 44 24 0c 69 5c 10 	movl   $0xf0105c69,0xc(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101edb:	f0 
f0101edc:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101ee3:	00 
f0101ee4:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101eeb:	e8 d6 e1 ff ff       	call   f01000c6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ef0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ef7:	e8 4e f4 ff ff       	call   f010134a <page_alloc>
f0101efc:	85 c0                	test   %eax,%eax
f0101efe:	74 24                	je     f0101f24 <check_page+0x3e2>
f0101f00:	c7 44 24 0c c0 5b 10 	movl   $0xf0105bc0,0xc(%esp)
f0101f07:	f0 
f0101f08:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101f0f:	f0 
f0101f10:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101f17:	00 
f0101f18:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101f1f:	e8 a2 e1 ff ff       	call   f01000c6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f24:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f2b:	00 
f0101f2c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f33:	00 
f0101f34:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f38:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101f3d:	89 04 24             	mov    %eax,(%esp)
f0101f40:	e8 93 fb ff ff       	call   f0101ad8 <page_insert>
f0101f45:	85 c0                	test   %eax,%eax
f0101f47:	74 24                	je     f0101f6d <check_page+0x42b>
f0101f49:	c7 44 24 0c f0 55 10 	movl   $0xf01055f0,0xc(%esp)
f0101f50:	f0 
f0101f51:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101f58:	f0 
f0101f59:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0101f60:	00 
f0101f61:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101f68:	e8 59 e1 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f6d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f72:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0101f77:	e8 55 ec ff ff       	call   f0100bd1 <check_va2pa>
f0101f7c:	89 c7                	mov    %eax,%edi
f0101f7e:	89 f0                	mov    %esi,%eax
f0101f80:	e8 3e eb ff ff       	call   f0100ac3 <page2pa>
f0101f85:	39 c7                	cmp    %eax,%edi
f0101f87:	74 24                	je     f0101fad <check_page+0x46b>
f0101f89:	c7 44 24 0c 2c 56 10 	movl   $0xf010562c,0xc(%esp)
f0101f90:	f0 
f0101f91:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101f98:	f0 
f0101f99:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101fa0:	00 
f0101fa1:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101fa8:	e8 19 e1 ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0101fad:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fb2:	74 24                	je     f0101fd8 <check_page+0x496>
f0101fb4:	c7 44 24 0c 69 5c 10 	movl   $0xf0105c69,0xc(%esp)
f0101fbb:	f0 
f0101fbc:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101fc3:	f0 
f0101fc4:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101fcb:	00 
f0101fcc:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0101fd3:	e8 ee e0 ff ff       	call   f01000c6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fd8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fdf:	e8 66 f3 ff ff       	call   f010134a <page_alloc>
f0101fe4:	85 c0                	test   %eax,%eax
f0101fe6:	74 24                	je     f010200c <check_page+0x4ca>
f0101fe8:	c7 44 24 0c c0 5b 10 	movl   $0xf0105bc0,0xc(%esp)
f0101fef:	f0 
f0101ff0:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101fff:	00 
f0102000:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102007:	e8 ba e0 ff ff       	call   f01000c6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010200c:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f0102012:	8b 0f                	mov    (%edi),%ecx
f0102014:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010201a:	ba 5d 03 00 00       	mov    $0x35d,%edx
f010201f:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0102024:	e8 52 eb ff ff       	call   f0100b7b <_kaddr>
f0102029:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010202c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102033:	00 
f0102034:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010203b:	00 
f010203c:	89 3c 24             	mov    %edi,(%esp)
f010203f:	e8 70 f8 ff ff       	call   f01018b4 <pgdir_walk>
f0102044:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102047:	8d 51 04             	lea    0x4(%ecx),%edx
f010204a:	39 d0                	cmp    %edx,%eax
f010204c:	74 24                	je     f0102072 <check_page+0x530>
f010204e:	c7 44 24 0c 5c 56 10 	movl   $0xf010565c,0xc(%esp)
f0102055:	f0 
f0102056:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010205d:	f0 
f010205e:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102065:	00 
f0102066:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010206d:	e8 54 e0 ff ff       	call   f01000c6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102072:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102079:	00 
f010207a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102081:	00 
f0102082:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102086:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f010208b:	89 04 24             	mov    %eax,(%esp)
f010208e:	e8 45 fa ff ff       	call   f0101ad8 <page_insert>
f0102093:	85 c0                	test   %eax,%eax
f0102095:	74 24                	je     f01020bb <check_page+0x579>
f0102097:	c7 44 24 0c 9c 56 10 	movl   $0xf010569c,0xc(%esp)
f010209e:	f0 
f010209f:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01020a6:	f0 
f01020a7:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01020ae:	00 
f01020af:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01020b6:	e8 0b e0 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020bb:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f01020c1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020c6:	89 f8                	mov    %edi,%eax
f01020c8:	e8 04 eb ff ff       	call   f0100bd1 <check_va2pa>
f01020cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020d0:	89 f0                	mov    %esi,%eax
f01020d2:	e8 ec e9 ff ff       	call   f0100ac3 <page2pa>
f01020d7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020da:	74 24                	je     f0102100 <check_page+0x5be>
f01020dc:	c7 44 24 0c 2c 56 10 	movl   $0xf010562c,0xc(%esp)
f01020e3:	f0 
f01020e4:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01020eb:	f0 
f01020ec:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01020f3:	00 
f01020f4:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01020fb:	e8 c6 df ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0102100:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102105:	74 24                	je     f010212b <check_page+0x5e9>
f0102107:	c7 44 24 0c 69 5c 10 	movl   $0xf0105c69,0xc(%esp)
f010210e:	f0 
f010210f:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102116:	f0 
f0102117:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f010211e:	00 
f010211f:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102126:	e8 9b df ff ff       	call   f01000c6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010212b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102132:	00 
f0102133:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010213a:	00 
f010213b:	89 3c 24             	mov    %edi,(%esp)
f010213e:	e8 71 f7 ff ff       	call   f01018b4 <pgdir_walk>
f0102143:	f6 00 04             	testb  $0x4,(%eax)
f0102146:	75 24                	jne    f010216c <check_page+0x62a>
f0102148:	c7 44 24 0c dc 56 10 	movl   $0xf01056dc,0xc(%esp)
f010214f:	f0 
f0102150:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102157:	f0 
f0102158:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010215f:	00 
f0102160:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102167:	e8 5a df ff ff       	call   f01000c6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010216c:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102171:	f6 00 04             	testb  $0x4,(%eax)
f0102174:	75 24                	jne    f010219a <check_page+0x658>
f0102176:	c7 44 24 0c 7a 5c 10 	movl   $0xf0105c7a,0xc(%esp)
f010217d:	f0 
f010217e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102185:	f0 
f0102186:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010218d:	00 
f010218e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102195:	e8 2c df ff ff       	call   f01000c6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010219a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021a1:	00 
f01021a2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021a9:	00 
f01021aa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021ae:	89 04 24             	mov    %eax,(%esp)
f01021b1:	e8 22 f9 ff ff       	call   f0101ad8 <page_insert>
f01021b6:	85 c0                	test   %eax,%eax
f01021b8:	74 24                	je     f01021de <check_page+0x69c>
f01021ba:	c7 44 24 0c f0 55 10 	movl   $0xf01055f0,0xc(%esp)
f01021c1:	f0 
f01021c2:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01021d1:	00 
f01021d2:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01021d9:	e8 e8 de ff ff       	call   f01000c6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01021de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021e5:	00 
f01021e6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021ed:	00 
f01021ee:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01021f3:	89 04 24             	mov    %eax,(%esp)
f01021f6:	e8 b9 f6 ff ff       	call   f01018b4 <pgdir_walk>
f01021fb:	f6 00 02             	testb  $0x2,(%eax)
f01021fe:	75 24                	jne    f0102224 <check_page+0x6e2>
f0102200:	c7 44 24 0c 10 57 10 	movl   $0xf0105710,0xc(%esp)
f0102207:	f0 
f0102208:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010220f:	f0 
f0102210:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102217:	00 
f0102218:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010221f:	e8 a2 de ff ff       	call   f01000c6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102224:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010222b:	00 
f010222c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102233:	00 
f0102234:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102239:	89 04 24             	mov    %eax,(%esp)
f010223c:	e8 73 f6 ff ff       	call   f01018b4 <pgdir_walk>
f0102241:	f6 00 04             	testb  $0x4,(%eax)
f0102244:	74 24                	je     f010226a <check_page+0x728>
f0102246:	c7 44 24 0c 44 57 10 	movl   $0xf0105744,0xc(%esp)
f010224d:	f0 
f010224e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102255:	f0 
f0102256:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010225d:	00 
f010225e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102265:	e8 5c de ff ff       	call   f01000c6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010226a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102271:	00 
f0102272:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102279:	00 
f010227a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010227d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102281:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102286:	89 04 24             	mov    %eax,(%esp)
f0102289:	e8 4a f8 ff ff       	call   f0101ad8 <page_insert>
f010228e:	85 c0                	test   %eax,%eax
f0102290:	78 24                	js     f01022b6 <check_page+0x774>
f0102292:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f0102299:	f0 
f010229a:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01022a1:	f0 
f01022a2:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01022a9:	00 
f01022aa:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01022b1:	e8 10 de ff ff       	call   f01000c6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01022b6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022bd:	00 
f01022be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022c5:	00 
f01022c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022ca:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01022cf:	89 04 24             	mov    %eax,(%esp)
f01022d2:	e8 01 f8 ff ff       	call   f0101ad8 <page_insert>
f01022d7:	85 c0                	test   %eax,%eax
f01022d9:	74 24                	je     f01022ff <check_page+0x7bd>
f01022db:	c7 44 24 0c b4 57 10 	movl   $0xf01057b4,0xc(%esp)
f01022e2:	f0 
f01022e3:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01022ea:	f0 
f01022eb:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f01022f2:	00 
f01022f3:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01022fa:	e8 c7 dd ff ff       	call   f01000c6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022ff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102306:	00 
f0102307:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010230e:	00 
f010230f:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102314:	89 04 24             	mov    %eax,(%esp)
f0102317:	e8 98 f5 ff ff       	call   f01018b4 <pgdir_walk>
f010231c:	f6 00 04             	testb  $0x4,(%eax)
f010231f:	74 24                	je     f0102345 <check_page+0x803>
f0102321:	c7 44 24 0c 44 57 10 	movl   $0xf0105744,0xc(%esp)
f0102328:	f0 
f0102329:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102330:	f0 
f0102331:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102338:	00 
f0102339:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102340:	e8 81 dd ff ff       	call   f01000c6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102345:	8b 3d 88 6f 18 f0    	mov    0xf0186f88,%edi
f010234b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102350:	89 f8                	mov    %edi,%eax
f0102352:	e8 7a e8 ff ff       	call   f0100bd1 <check_va2pa>
f0102357:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010235a:	89 d8                	mov    %ebx,%eax
f010235c:	e8 62 e7 ff ff       	call   f0100ac3 <page2pa>
f0102361:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102364:	74 24                	je     f010238a <check_page+0x848>
f0102366:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f010236d:	f0 
f010236e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102375:	f0 
f0102376:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010237d:	00 
f010237e:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102385:	e8 3c dd ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010238a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010238f:	89 f8                	mov    %edi,%eax
f0102391:	e8 3b e8 ff ff       	call   f0100bd1 <check_va2pa>
f0102396:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102399:	74 24                	je     f01023bf <check_page+0x87d>
f010239b:	c7 44 24 0c 1c 58 10 	movl   $0xf010581c,0xc(%esp)
f01023a2:	f0 
f01023a3:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f01023b2:	00 
f01023b3:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01023ba:	e8 07 dd ff ff       	call   f01000c6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01023bf:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01023c4:	74 24                	je     f01023ea <check_page+0x8a8>
f01023c6:	c7 44 24 0c 90 5c 10 	movl   $0xf0105c90,0xc(%esp)
f01023cd:	f0 
f01023ce:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01023d5:	f0 
f01023d6:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01023dd:	00 
f01023de:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01023e5:	e8 dc dc ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 0);
f01023ea:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023ef:	74 24                	je     f0102415 <check_page+0x8d3>
f01023f1:	c7 44 24 0c a1 5c 10 	movl   $0xf0105ca1,0xc(%esp)
f01023f8:	f0 
f01023f9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102400:	f0 
f0102401:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0102408:	00 
f0102409:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102410:	e8 b1 dc ff ff       	call   f01000c6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102415:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010241c:	e8 29 ef ff ff       	call   f010134a <page_alloc>
f0102421:	89 c7                	mov    %eax,%edi
f0102423:	85 c0                	test   %eax,%eax
f0102425:	74 04                	je     f010242b <check_page+0x8e9>
f0102427:	39 f0                	cmp    %esi,%eax
f0102429:	74 24                	je     f010244f <check_page+0x90d>
f010242b:	c7 44 24 0c 4c 58 10 	movl   $0xf010584c,0xc(%esp)
f0102432:	f0 
f0102433:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010243a:	f0 
f010243b:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102442:	00 
f0102443:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010244a:	e8 77 dc ff ff       	call   f01000c6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010244f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102456:	00 
f0102457:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f010245c:	89 04 24             	mov    %eax,(%esp)
f010245f:	e8 2b f6 ff ff       	call   f0101a8f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102464:	8b 35 88 6f 18 f0    	mov    0xf0186f88,%esi
f010246a:	ba 00 00 00 00       	mov    $0x0,%edx
f010246f:	89 f0                	mov    %esi,%eax
f0102471:	e8 5b e7 ff ff       	call   f0100bd1 <check_va2pa>
f0102476:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102479:	74 24                	je     f010249f <check_page+0x95d>
f010247b:	c7 44 24 0c 70 58 10 	movl   $0xf0105870,0xc(%esp)
f0102482:	f0 
f0102483:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010248a:	f0 
f010248b:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102492:	00 
f0102493:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010249a:	e8 27 dc ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010249f:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024a4:	89 f0                	mov    %esi,%eax
f01024a6:	e8 26 e7 ff ff       	call   f0100bd1 <check_va2pa>
f01024ab:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01024ae:	89 d8                	mov    %ebx,%eax
f01024b0:	e8 0e e6 ff ff       	call   f0100ac3 <page2pa>
f01024b5:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01024b8:	74 24                	je     f01024de <check_page+0x99c>
f01024ba:	c7 44 24 0c 1c 58 10 	movl   $0xf010581c,0xc(%esp)
f01024c1:	f0 
f01024c2:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01024c9:	f0 
f01024ca:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01024d1:	00 
f01024d2:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01024d9:	e8 e8 db ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 1);
f01024de:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024e3:	74 24                	je     f0102509 <check_page+0x9c7>
f01024e5:	c7 44 24 0c 47 5c 10 	movl   $0xf0105c47,0xc(%esp)
f01024ec:	f0 
f01024ed:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01024f4:	f0 
f01024f5:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f01024fc:	00 
f01024fd:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102504:	e8 bd db ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 0);
f0102509:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010250e:	74 24                	je     f0102534 <check_page+0x9f2>
f0102510:	c7 44 24 0c a1 5c 10 	movl   $0xf0105ca1,0xc(%esp)
f0102517:	f0 
f0102518:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010251f:	f0 
f0102520:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102527:	00 
f0102528:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010252f:	e8 92 db ff ff       	call   f01000c6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102534:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010253b:	00 
f010253c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102543:	00 
f0102544:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102548:	89 34 24             	mov    %esi,(%esp)
f010254b:	e8 88 f5 ff ff       	call   f0101ad8 <page_insert>
f0102550:	85 c0                	test   %eax,%eax
f0102552:	74 24                	je     f0102578 <check_page+0xa36>
f0102554:	c7 44 24 0c 94 58 10 	movl   $0xf0105894,0xc(%esp)
f010255b:	f0 
f010255c:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102563:	f0 
f0102564:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010256b:	00 
f010256c:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102573:	e8 4e db ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref);
f0102578:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010257d:	75 24                	jne    f01025a3 <check_page+0xa61>
f010257f:	c7 44 24 0c b2 5c 10 	movl   $0xf0105cb2,0xc(%esp)
f0102586:	f0 
f0102587:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010258e:	f0 
f010258f:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102596:	00 
f0102597:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010259e:	e8 23 db ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_link == NULL);
f01025a3:	83 3b 00             	cmpl   $0x0,(%ebx)
f01025a6:	74 24                	je     f01025cc <check_page+0xa8a>
f01025a8:	c7 44 24 0c be 5c 10 	movl   $0xf0105cbe,0xc(%esp)
f01025af:	f0 
f01025b0:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01025b7:	f0 
f01025b8:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01025bf:	00 
f01025c0:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01025c7:	e8 fa da ff ff       	call   f01000c6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025cc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025d3:	00 
f01025d4:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01025d9:	89 04 24             	mov    %eax,(%esp)
f01025dc:	e8 ae f4 ff ff       	call   f0101a8f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025e1:	8b 35 88 6f 18 f0    	mov    0xf0186f88,%esi
f01025e7:	ba 00 00 00 00       	mov    $0x0,%edx
f01025ec:	89 f0                	mov    %esi,%eax
f01025ee:	e8 de e5 ff ff       	call   f0100bd1 <check_va2pa>
f01025f3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025f6:	74 24                	je     f010261c <check_page+0xada>
f01025f8:	c7 44 24 0c 70 58 10 	movl   $0xf0105870,0xc(%esp)
f01025ff:	f0 
f0102600:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102607:	f0 
f0102608:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f010260f:	00 
f0102610:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102617:	e8 aa da ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010261c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102621:	89 f0                	mov    %esi,%eax
f0102623:	e8 a9 e5 ff ff       	call   f0100bd1 <check_va2pa>
f0102628:	83 f8 ff             	cmp    $0xffffffff,%eax
f010262b:	74 24                	je     f0102651 <check_page+0xb0f>
f010262d:	c7 44 24 0c cc 58 10 	movl   $0xf01058cc,0xc(%esp)
f0102634:	f0 
f0102635:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010263c:	f0 
f010263d:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102644:	00 
f0102645:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010264c:	e8 75 da ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 0);
f0102651:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102656:	74 24                	je     f010267c <check_page+0xb3a>
f0102658:	c7 44 24 0c d3 5c 10 	movl   $0xf0105cd3,0xc(%esp)
f010265f:	f0 
f0102660:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102667:	f0 
f0102668:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010266f:	00 
f0102670:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102677:	e8 4a da ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 0);
f010267c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102681:	74 24                	je     f01026a7 <check_page+0xb65>
f0102683:	c7 44 24 0c a1 5c 10 	movl   $0xf0105ca1,0xc(%esp)
f010268a:	f0 
f010268b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102692:	f0 
f0102693:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010269a:	00 
f010269b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01026a2:	e8 1f da ff ff       	call   f01000c6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01026a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026ae:	e8 97 ec ff ff       	call   f010134a <page_alloc>
f01026b3:	89 c6                	mov    %eax,%esi
f01026b5:	85 c0                	test   %eax,%eax
f01026b7:	74 04                	je     f01026bd <check_page+0xb7b>
f01026b9:	39 d8                	cmp    %ebx,%eax
f01026bb:	74 24                	je     f01026e1 <check_page+0xb9f>
f01026bd:	c7 44 24 0c f4 58 10 	movl   $0xf01058f4,0xc(%esp)
f01026c4:	f0 
f01026c5:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01026cc:	f0 
f01026cd:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01026d4:	00 
f01026d5:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f01026dc:	e8 e5 d9 ff ff       	call   f01000c6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01026e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026e8:	e8 5d ec ff ff       	call   f010134a <page_alloc>
f01026ed:	85 c0                	test   %eax,%eax
f01026ef:	74 24                	je     f0102715 <check_page+0xbd3>
f01026f1:	c7 44 24 0c c0 5b 10 	movl   $0xf0105bc0,0xc(%esp)
f01026f8:	f0 
f01026f9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102700:	f0 
f0102701:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102708:	00 
f0102709:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102710:	e8 b1 d9 ff ff       	call   f01000c6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102715:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f010271b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010271e:	e8 a0 e3 ff ff       	call   f0100ac3 <page2pa>
f0102723:	8b 13                	mov    (%ebx),%edx
f0102725:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010272b:	39 c2                	cmp    %eax,%edx
f010272d:	74 24                	je     f0102753 <check_page+0xc11>
f010272f:	c7 44 24 0c 98 55 10 	movl   $0xf0105598,0xc(%esp)
f0102736:	f0 
f0102737:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010273e:	f0 
f010273f:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102746:	00 
f0102747:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010274e:	e8 73 d9 ff ff       	call   f01000c6 <_panic>
	kern_pgdir[0] = 0;
f0102753:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102759:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010275c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102761:	74 24                	je     f0102787 <check_page+0xc45>
f0102763:	c7 44 24 0c 58 5c 10 	movl   $0xf0105c58,0xc(%esp)
f010276a:	f0 
f010276b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102772:	f0 
f0102773:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f010277a:	00 
f010277b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102782:	e8 3f d9 ff ff       	call   f01000c6 <_panic>
	pp0->pp_ref = 0;
f0102787:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010278a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102790:	89 04 24             	mov    %eax,(%esp)
f0102793:	e8 04 ec ff ff       	call   f010139c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102798:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010279f:	00 
f01027a0:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01027a7:	00 
f01027a8:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01027ad:	89 04 24             	mov    %eax,(%esp)
f01027b0:	e8 ff f0 ff ff       	call   f01018b4 <pgdir_walk>
f01027b5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01027b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01027bb:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f01027c1:	8b 4b 04             	mov    0x4(%ebx),%ecx
f01027c4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01027ca:	ba a0 03 00 00       	mov    $0x3a0,%edx
f01027cf:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f01027d4:	e8 a2 e3 ff ff       	call   f0100b7b <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01027d9:	83 c0 04             	add    $0x4,%eax
f01027dc:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01027df:	74 24                	je     f0102805 <check_page+0xcc3>
f01027e1:	c7 44 24 0c e4 5c 10 	movl   $0xf0105ce4,0xc(%esp)
f01027e8:	f0 
f01027e9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01027f0:	f0 
f01027f1:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01027f8:	00 
f01027f9:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102800:	e8 c1 d8 ff ff       	call   f01000c6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102805:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f010280c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010280f:	89 d8                	mov    %ebx,%eax
f0102811:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102817:	e8 97 e3 ff ff       	call   f0100bb3 <page2kva>
f010281c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102823:	00 
f0102824:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010282b:	00 
f010282c:	89 04 24             	mov    %eax,(%esp)
f010282f:	e8 f3 1f 00 00       	call   f0104827 <memset>
	page_free(pp0);
f0102834:	89 1c 24             	mov    %ebx,(%esp)
f0102837:	e8 60 eb ff ff       	call   f010139c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010283c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102843:	00 
f0102844:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010284b:	00 
f010284c:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102851:	89 04 24             	mov    %eax,(%esp)
f0102854:	e8 5b f0 ff ff       	call   f01018b4 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f0102859:	89 d8                	mov    %ebx,%eax
f010285b:	e8 53 e3 ff ff       	call   f0100bb3 <page2kva>
f0102860:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
f0102863:	ba 00 00 00 00       	mov    $0x0,%edx
		assert((ptep[i] & PTE_P) == 0);
f0102868:	f6 04 90 01          	testb  $0x1,(%eax,%edx,4)
f010286c:	74 24                	je     f0102892 <check_page+0xd50>
f010286e:	c7 44 24 0c fc 5c 10 	movl   $0xf0105cfc,0xc(%esp)
f0102875:	f0 
f0102876:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010287d:	f0 
f010287e:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102885:	00 
f0102886:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010288d:	e8 34 d8 ff ff       	call   f01000c6 <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102892:	83 c2 01             	add    $0x1,%edx
f0102895:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f010289b:	75 cb                	jne    f0102868 <check_page+0xd26>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010289d:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01028a2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01028a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028ab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01028b1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01028b4:	89 0d bc 52 18 f0    	mov    %ecx,0xf01852bc

	// free the pages we took
	page_free(pp0);
f01028ba:	89 04 24             	mov    %eax,(%esp)
f01028bd:	e8 da ea ff ff       	call   f010139c <page_free>
	page_free(pp1);
f01028c2:	89 34 24             	mov    %esi,(%esp)
f01028c5:	e8 d2 ea ff ff       	call   f010139c <page_free>
	page_free(pp2);
f01028ca:	89 3c 24             	mov    %edi,(%esp)
f01028cd:	e8 ca ea ff ff       	call   f010139c <page_free>

	cprintf("check_page() succeeded!\n");
f01028d2:	c7 04 24 13 5d 10 f0 	movl   $0xf0105d13,(%esp)
f01028d9:	e8 84 0f 00 00       	call   f0103862 <cprintf>
}
f01028de:	83 c4 3c             	add    $0x3c,%esp
f01028e1:	5b                   	pop    %ebx
f01028e2:	5e                   	pop    %esi
f01028e3:	5f                   	pop    %edi
f01028e4:	5d                   	pop    %ebp
f01028e5:	c3                   	ret    

f01028e6 <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f01028e6:	55                   	push   %ebp
f01028e7:	89 e5                	mov    %esp,%ebp
f01028e9:	57                   	push   %edi
f01028ea:	56                   	push   %esi
f01028eb:	53                   	push   %ebx
f01028ec:	83 ec 1c             	sub    $0x1c,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01028ef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028f6:	e8 4f ea ff ff       	call   f010134a <page_alloc>
f01028fb:	89 c6                	mov    %eax,%esi
f01028fd:	85 c0                	test   %eax,%eax
f01028ff:	75 24                	jne    f0102925 <check_page_installed_pgdir+0x3f>
f0102901:	c7 44 24 0c 15 5b 10 	movl   $0xf0105b15,0xc(%esp)
f0102908:	f0 
f0102909:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102910:	f0 
f0102911:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f0102918:	00 
f0102919:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102920:	e8 a1 d7 ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102925:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010292c:	e8 19 ea ff ff       	call   f010134a <page_alloc>
f0102931:	89 c7                	mov    %eax,%edi
f0102933:	85 c0                	test   %eax,%eax
f0102935:	75 24                	jne    f010295b <check_page_installed_pgdir+0x75>
f0102937:	c7 44 24 0c 2b 5b 10 	movl   $0xf0105b2b,0xc(%esp)
f010293e:	f0 
f010293f:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102946:	f0 
f0102947:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f010294e:	00 
f010294f:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102956:	e8 6b d7 ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f010295b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102962:	e8 e3 e9 ff ff       	call   f010134a <page_alloc>
f0102967:	89 c3                	mov    %eax,%ebx
f0102969:	85 c0                	test   %eax,%eax
f010296b:	75 24                	jne    f0102991 <check_page_installed_pgdir+0xab>
f010296d:	c7 44 24 0c 41 5b 10 	movl   $0xf0105b41,0xc(%esp)
f0102974:	f0 
f0102975:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010297c:	f0 
f010297d:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102984:	00 
f0102985:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f010298c:	e8 35 d7 ff ff       	call   f01000c6 <_panic>
	page_free(pp0);
f0102991:	89 34 24             	mov    %esi,(%esp)
f0102994:	e8 03 ea ff ff       	call   f010139c <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102999:	89 f8                	mov    %edi,%eax
f010299b:	e8 13 e2 ff ff       	call   f0100bb3 <page2kva>
f01029a0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029a7:	00 
f01029a8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01029af:	00 
f01029b0:	89 04 24             	mov    %eax,(%esp)
f01029b3:	e8 6f 1e 00 00       	call   f0104827 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01029b8:	89 d8                	mov    %ebx,%eax
f01029ba:	e8 f4 e1 ff ff       	call   f0100bb3 <page2kva>
f01029bf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029c6:	00 
f01029c7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029ce:	00 
f01029cf:	89 04 24             	mov    %eax,(%esp)
f01029d2:	e8 50 1e 00 00       	call   f0104827 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029d7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029de:	00 
f01029df:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029e6:	00 
f01029e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01029eb:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f01029f0:	89 04 24             	mov    %eax,(%esp)
f01029f3:	e8 e0 f0 ff ff       	call   f0101ad8 <page_insert>
	assert(pp1->pp_ref == 1);
f01029f8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029fd:	74 24                	je     f0102a23 <check_page_installed_pgdir+0x13d>
f01029ff:	c7 44 24 0c 47 5c 10 	movl   $0xf0105c47,0xc(%esp)
f0102a06:	f0 
f0102a07:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102a0e:	f0 
f0102a0f:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102a16:	00 
f0102a17:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102a1e:	e8 a3 d6 ff ff       	call   f01000c6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a23:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a2a:	01 01 01 
f0102a2d:	74 24                	je     f0102a53 <check_page_installed_pgdir+0x16d>
f0102a2f:	c7 44 24 0c 18 59 10 	movl   $0xf0105918,0xc(%esp)
f0102a36:	f0 
f0102a37:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102a3e:	f0 
f0102a3f:	c7 44 24 04 ce 03 00 	movl   $0x3ce,0x4(%esp)
f0102a46:	00 
f0102a47:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102a4e:	e8 73 d6 ff ff       	call   f01000c6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a53:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a5a:	00 
f0102a5b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a62:	00 
f0102a63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a67:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102a6c:	89 04 24             	mov    %eax,(%esp)
f0102a6f:	e8 64 f0 ff ff       	call   f0101ad8 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a74:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a7b:	02 02 02 
f0102a7e:	74 24                	je     f0102aa4 <check_page_installed_pgdir+0x1be>
f0102a80:	c7 44 24 0c 3c 59 10 	movl   $0xf010593c,0xc(%esp)
f0102a87:	f0 
f0102a88:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102a8f:	f0 
f0102a90:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0102a97:	00 
f0102a98:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102a9f:	e8 22 d6 ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0102aa4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102aa9:	74 24                	je     f0102acf <check_page_installed_pgdir+0x1e9>
f0102aab:	c7 44 24 0c 69 5c 10 	movl   $0xf0105c69,0xc(%esp)
f0102ab2:	f0 
f0102ab3:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102aba:	f0 
f0102abb:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102ac2:	00 
f0102ac3:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102aca:	e8 f7 d5 ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 0);
f0102acf:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ad4:	74 24                	je     f0102afa <check_page_installed_pgdir+0x214>
f0102ad6:	c7 44 24 0c d3 5c 10 	movl   $0xf0105cd3,0xc(%esp)
f0102add:	f0 
f0102ade:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102ae5:	f0 
f0102ae6:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102aed:	00 
f0102aee:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102af5:	e8 cc d5 ff ff       	call   f01000c6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102afa:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b01:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b04:	89 d8                	mov    %ebx,%eax
f0102b06:	e8 a8 e0 ff ff       	call   f0100bb3 <page2kva>
f0102b0b:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102b11:	74 24                	je     f0102b37 <check_page_installed_pgdir+0x251>
f0102b13:	c7 44 24 0c 60 59 10 	movl   $0xf0105960,0xc(%esp)
f0102b1a:	f0 
f0102b1b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102b22:	f0 
f0102b23:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0102b2a:	00 
f0102b2b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102b32:	e8 8f d5 ff ff       	call   f01000c6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b37:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b3e:	00 
f0102b3f:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102b44:	89 04 24             	mov    %eax,(%esp)
f0102b47:	e8 43 ef ff ff       	call   f0101a8f <page_remove>
	assert(pp2->pp_ref == 0);
f0102b4c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102b51:	74 24                	je     f0102b77 <check_page_installed_pgdir+0x291>
f0102b53:	c7 44 24 0c a1 5c 10 	movl   $0xf0105ca1,0xc(%esp)
f0102b5a:	f0 
f0102b5b:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102b62:	f0 
f0102b63:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0102b6a:	00 
f0102b6b:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102b72:	e8 4f d5 ff ff       	call   f01000c6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b77:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0102b7d:	89 f0                	mov    %esi,%eax
f0102b7f:	e8 3f df ff ff       	call   f0100ac3 <page2pa>
f0102b84:	8b 13                	mov    (%ebx),%edx
f0102b86:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b8c:	39 c2                	cmp    %eax,%edx
f0102b8e:	74 24                	je     f0102bb4 <check_page_installed_pgdir+0x2ce>
f0102b90:	c7 44 24 0c 98 55 10 	movl   $0xf0105598,0xc(%esp)
f0102b97:	f0 
f0102b98:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102b9f:	f0 
f0102ba0:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102ba7:	00 
f0102ba8:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102baf:	e8 12 d5 ff ff       	call   f01000c6 <_panic>
	kern_pgdir[0] = 0;
f0102bb4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102bba:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bbf:	74 24                	je     f0102be5 <check_page_installed_pgdir+0x2ff>
f0102bc1:	c7 44 24 0c 58 5c 10 	movl   $0xf0105c58,0xc(%esp)
f0102bc8:	f0 
f0102bc9:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0102bd0:	f0 
f0102bd1:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102bd8:	00 
f0102bd9:	c7 04 24 fb 59 10 f0 	movl   $0xf01059fb,(%esp)
f0102be0:	e8 e1 d4 ff ff       	call   f01000c6 <_panic>
	pp0->pp_ref = 0;
f0102be5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102beb:	89 34 24             	mov    %esi,(%esp)
f0102bee:	e8 a9 e7 ff ff       	call   f010139c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bf3:	c7 04 24 8c 59 10 f0 	movl   $0xf010598c,(%esp)
f0102bfa:	e8 63 0c 00 00       	call   f0103862 <cprintf>
}
f0102bff:	83 c4 1c             	add    $0x1c,%esp
f0102c02:	5b                   	pop    %ebx
f0102c03:	5e                   	pop    %esi
f0102c04:	5f                   	pop    %edi
f0102c05:	5d                   	pop    %ebp
f0102c06:	c3                   	ret    

f0102c07 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0102c07:	55                   	push   %ebp
f0102c08:	89 e5                	mov    %esp,%ebp
f0102c0a:	53                   	push   %ebx
f0102c0b:	83 ec 14             	sub    $0x14,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f0102c0e:	e8 ec de ff ff       	call   f0100aff <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0102c13:	b8 00 10 00 00       	mov    $0x1000,%eax
f0102c18:	e8 4d e0 ff ff       	call   f0100c6a <boot_alloc>
f0102c1d:	a3 88 6f 18 f0       	mov    %eax,0xf0186f88
	memset(kern_pgdir, 0, PGSIZE);
f0102c22:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c29:	00 
f0102c2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c31:	00 
f0102c32:	89 04 24             	mov    %eax,(%esp)
f0102c35:	e8 ed 1b 00 00       	call   f0104827 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102c3a:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0102c40:	89 d9                	mov    %ebx,%ecx
f0102c42:	ba 93 00 00 00       	mov    $0x93,%edx
f0102c47:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0102c4c:	e8 ec df ff ff       	call   f0100c3d <_paddr>
f0102c51:	83 c8 05             	or     $0x5,%eax
f0102c54:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102c5a:	a1 84 6f 18 f0       	mov    0xf0186f84,%eax
f0102c5f:	c1 e0 03             	shl    $0x3,%eax
f0102c62:	e8 03 e0 ff ff       	call   f0100c6a <boot_alloc>
f0102c67:	a3 8c 6f 18 f0       	mov    %eax,0xf0186f8c
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102c6c:	8b 1d 84 6f 18 f0    	mov    0xf0186f84,%ebx
f0102c72:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102c79:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102c7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c84:	00 
f0102c85:	89 04 24             	mov    %eax,(%esp)
f0102c88:	e8 9a 1b 00 00       	call   f0104827 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f0102c8d:	b8 00 80 01 00       	mov    $0x18000,%eax
f0102c92:	e8 d3 df ff ff       	call   f0100c6a <boot_alloc>
f0102c97:	a3 c8 52 18 f0       	mov    %eax,0xf01852c8
	memset(envs,0, NENV*sizeof(struct Env));
f0102c9c:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0102ca3:	00 
f0102ca4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102cab:	00 
f0102cac:	89 04 24             	mov    %eax,(%esp)
f0102caf:	e8 73 1b 00 00       	call   f0104827 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0102cb4:	e8 21 e6 ff ff       	call   f01012da <page_init>

	check_page_free_list(1);
f0102cb9:	b8 01 00 00 00       	mov    $0x1,%eax
f0102cbe:	e8 f3 e2 ff ff       	call   f0100fb6 <check_page_free_list>
	check_page_alloc();
f0102cc3:	e8 30 e7 ff ff       	call   f01013f8 <check_page_alloc>
	check_page();
f0102cc8:	e8 75 ee ff ff       	call   f0101b42 <check_page>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,npages*sizeof(struct PageInfo),PADDR(pages),PTE_U|PTE_P);
f0102ccd:	8b 0d 8c 6f 18 f0    	mov    0xf0186f8c,%ecx
f0102cd3:	ba bd 00 00 00       	mov    $0xbd,%edx
f0102cd8:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0102cdd:	e8 5b df ff ff       	call   f0100c3d <_paddr>
f0102ce2:	8b 1d 84 6f 18 f0    	mov    0xf0186f84,%ebx
f0102ce8:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102cef:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102cf6:	00 
f0102cf7:	89 04 24             	mov    %eax,(%esp)
f0102cfa:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102cff:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d04:	e8 46 ec ff ff       	call   f010194f <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f0102d09:	8b 0d c8 52 18 f0    	mov    0xf01852c8,%ecx
f0102d0f:	ba c5 00 00 00       	mov    $0xc5,%edx
f0102d14:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0102d19:	e8 1f df ff ff       	call   f0100c3d <_paddr>
f0102d1e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d25:	00 
f0102d26:	89 04 24             	mov    %eax,(%esp)
f0102d29:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102d2e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102d33:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d38:	e8 12 ec ff ff       	call   f010194f <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f0102d3d:	b9 00 20 11 f0       	mov    $0xf0112000,%ecx
f0102d42:	ba d2 00 00 00       	mov    $0xd2,%edx
f0102d47:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0102d4c:	e8 ec de ff ff       	call   f0100c3d <_paddr>
f0102d51:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d58:	00 
f0102d59:	89 04 24             	mov    %eax,(%esp)
f0102d5c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102d61:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102d66:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d6b:	e8 df eb ff ff       	call   f010194f <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,~0x0-KERNBASE+1,0,PTE_P|PTE_W);
f0102d70:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d77:	00 
f0102d78:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102d7f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102d84:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102d89:	a1 88 6f 18 f0       	mov    0xf0186f88,%eax
f0102d8e:	e8 bc eb ff ff       	call   f010194f <boot_map_region>
	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102d93:	e8 57 df ff ff       	call   f0100cef <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102d98:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f0102d9e:	ba e7 00 00 00       	mov    $0xe7,%edx
f0102da3:	b8 fb 59 10 f0       	mov    $0xf01059fb,%eax
f0102da8:	e8 90 de ff ff       	call   f0100c3d <_paddr>
f0102dad:	e8 09 dd ff ff       	call   f0100abb <lcr3>

	check_page_free_list(0);
f0102db2:	b8 00 00 00 00       	mov    $0x0,%eax
f0102db7:	e8 fa e1 ff ff       	call   f0100fb6 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f0102dbc:	e8 f2 dc ff ff       	call   f0100ab3 <rcr0>
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102dc1:	83 e0 f3             	and    $0xfffffff3,%eax
f0102dc4:	0d 23 00 05 80       	or     $0x80050023,%eax
	lcr0(cr0);
f0102dc9:	e8 dd dc ff ff       	call   f0100aab <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f0102dce:	e8 13 fb ff ff       	call   f01028e6 <check_page_installed_pgdir>
}
f0102dd3:	83 c4 14             	add    $0x14,%esp
f0102dd6:	5b                   	pop    %ebx
f0102dd7:	5d                   	pop    %ebp
f0102dd8:	c3                   	ret    

f0102dd9 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102dd9:	55                   	push   %ebp
f0102dda:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102ddc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102de1:	5d                   	pop    %ebp
f0102de2:	c3                   	ret    

f0102de3 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102de3:	55                   	push   %ebp
f0102de4:	89 e5                	mov    %esp,%ebp
f0102de6:	53                   	push   %ebx
f0102de7:	83 ec 14             	sub    $0x14,%esp
f0102dea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102ded:	8b 45 14             	mov    0x14(%ebp),%eax
f0102df0:	83 c8 04             	or     $0x4,%eax
f0102df3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102df7:	8b 45 10             	mov    0x10(%ebp),%eax
f0102dfa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102dfe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e01:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e05:	89 1c 24             	mov    %ebx,(%esp)
f0102e08:	e8 cc ff ff ff       	call   f0102dd9 <user_mem_check>
f0102e0d:	85 c0                	test   %eax,%eax
f0102e0f:	79 23                	jns    f0102e34 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102e11:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102e18:	00 
f0102e19:	8b 43 48             	mov    0x48(%ebx),%eax
f0102e1c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e20:	c7 04 24 b8 59 10 f0 	movl   $0xf01059b8,(%esp)
f0102e27:	e8 36 0a 00 00       	call   f0103862 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102e2c:	89 1c 24             	mov    %ebx,(%esp)
f0102e2f:	e8 b7 08 00 00       	call   f01036eb <env_destroy>
	}
}
f0102e34:	83 c4 14             	add    $0x14,%esp
f0102e37:	5b                   	pop    %ebx
f0102e38:	5d                   	pop    %ebp
f0102e39:	c3                   	ret    

f0102e3a <lgdt>:
	asm volatile("lidt (%0)" : : "r" (p));
}

static inline void
lgdt(void *p)
{
f0102e3a:	55                   	push   %ebp
f0102e3b:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f0102e3d:	0f 01 10             	lgdtl  (%eax)
}
f0102e40:	5d                   	pop    %ebp
f0102e41:	c3                   	ret    

f0102e42 <lldt>:

static inline void
lldt(uint16_t sel)
{
f0102e42:	55                   	push   %ebp
f0102e43:	89 e5                	mov    %esp,%ebp
	asm volatile("lldt %0" : : "r" (sel));
f0102e45:	0f 00 d0             	lldt   %ax
}
f0102e48:	5d                   	pop    %ebp
f0102e49:	c3                   	ret    

f0102e4a <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0102e4a:	55                   	push   %ebp
f0102e4b:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102e4d:	0f 22 d8             	mov    %eax,%cr3
}
f0102e50:	5d                   	pop    %ebp
f0102e51:	c3                   	ret    

f0102e52 <rcr3>:

static inline uint32_t
rcr3(void)
{
f0102e52:	55                   	push   %ebp
f0102e53:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr3,%0" : "=r" (val));
f0102e55:	0f 20 d8             	mov    %cr3,%eax
	return val;
}
f0102e58:	5d                   	pop    %ebp
f0102e59:	c3                   	ret    

f0102e5a <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0102e5a:	55                   	push   %ebp
f0102e5b:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0102e5d:	2b 05 8c 6f 18 f0    	sub    0xf0186f8c,%eax
f0102e63:	c1 f8 03             	sar    $0x3,%eax
f0102e66:	c1 e0 0c             	shl    $0xc,%eax
}
f0102e69:	5d                   	pop    %ebp
f0102e6a:	c3                   	ret    

f0102e6b <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0102e6b:	55                   	push   %ebp
f0102e6c:	89 e5                	mov    %esp,%ebp
f0102e6e:	53                   	push   %ebx
f0102e6f:	83 ec 14             	sub    $0x14,%esp
	if (PGNUM(pa) >= npages)
f0102e72:	89 cb                	mov    %ecx,%ebx
f0102e74:	c1 eb 0c             	shr    $0xc,%ebx
f0102e77:	3b 1d 84 6f 18 f0    	cmp    0xf0186f84,%ebx
f0102e7d:	72 18                	jb     f0102e97 <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e7f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102e83:	c7 44 24 08 40 52 10 	movl   $0xf0105240,0x8(%esp)
f0102e8a:	f0 
f0102e8b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102e8f:	89 04 24             	mov    %eax,(%esp)
f0102e92:	e8 2f d2 ff ff       	call   f01000c6 <_panic>
	return (void *)(pa + KERNBASE);
f0102e97:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0102e9d:	83 c4 14             	add    $0x14,%esp
f0102ea0:	5b                   	pop    %ebx
f0102ea1:	5d                   	pop    %ebp
f0102ea2:	c3                   	ret    

f0102ea3 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0102ea3:	55                   	push   %ebp
f0102ea4:	89 e5                	mov    %esp,%ebp
f0102ea6:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0102ea9:	e8 ac ff ff ff       	call   f0102e5a <page2pa>
f0102eae:	89 c1                	mov    %eax,%ecx
f0102eb0:	ba 56 00 00 00       	mov    $0x56,%edx
f0102eb5:	b8 ed 59 10 f0       	mov    $0xf01059ed,%eax
f0102eba:	e8 ac ff ff ff       	call   f0102e6b <_kaddr>
}
f0102ebf:	c9                   	leave  
f0102ec0:	c3                   	ret    

f0102ec1 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ec1:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0102ec7:	77 1e                	ja     f0102ee7 <_paddr+0x26>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0102ec9:	55                   	push   %ebp
f0102eca:	89 e5                	mov    %esp,%ebp
f0102ecc:	83 ec 18             	sub    $0x18,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ecf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102ed3:	c7 44 24 08 64 52 10 	movl   $0xf0105264,0x8(%esp)
f0102eda:	f0 
f0102edb:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102edf:	89 04 24             	mov    %eax,(%esp)
f0102ee2:	e8 df d1 ff ff       	call   f01000c6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ee7:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0102eed:	c3                   	ret    

f0102eee <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f0102eee:	55                   	push   %ebp
f0102eef:	89 e5                	mov    %esp,%ebp
f0102ef1:	56                   	push   %esi
f0102ef2:	53                   	push   %ebx
f0102ef3:	83 ec 10             	sub    $0x10,%esp
f0102ef6:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102ef8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0102eff:	e8 46 e4 ff ff       	call   f010134a <page_alloc>
f0102f04:	89 c3                	mov    %eax,%ebx
f0102f06:	85 c0                	test   %eax,%eax
f0102f08:	74 4b                	je     f0102f55 <env_setup_vm+0x67>
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	e->env_pgdir = page2kva(p);
f0102f0a:	e8 94 ff ff ff       	call   f0102ea3 <page2kva>
f0102f0f:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102f12:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102f19:	00 
f0102f1a:	8b 15 88 6f 18 f0    	mov    0xf0186f88,%edx
f0102f20:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102f24:	89 04 24             	mov    %eax,(%esp)
f0102f27:	e8 b1 19 00 00       	call   f01048dd <memcpy>
	p->pp_ref ++;
f0102f2c:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f31:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102f34:	89 d9                	mov    %ebx,%ecx
f0102f36:	ba bf 00 00 00       	mov    $0xbf,%edx
f0102f3b:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f0102f40:	e8 7c ff ff ff       	call   f0102ec1 <_paddr>
f0102f45:	83 c8 05             	or     $0x5,%eax
f0102f48:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f0102f4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f53:	eb 05                	jmp    f0102f5a <env_setup_vm+0x6c>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102f55:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f0102f5a:	83 c4 10             	add    $0x10,%esp
f0102f5d:	5b                   	pop    %ebx
f0102f5e:	5e                   	pop    %esi
f0102f5f:	5d                   	pop    %ebp
f0102f60:	c3                   	ret    

f0102f61 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f61:	c1 e8 0c             	shr    $0xc,%eax
f0102f64:	3b 05 84 6f 18 f0    	cmp    0xf0186f84,%eax
f0102f6a:	72 22                	jb     f0102f8e <pa2page+0x2d>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f0102f6c:	55                   	push   %ebp
f0102f6d:	89 e5                	mov    %esp,%ebp
f0102f6f:	83 ec 18             	sub    $0x18,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0102f72:	c7 44 24 08 74 54 10 	movl   $0xf0105474,0x8(%esp)
f0102f79:	f0 
f0102f7a:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102f81:	00 
f0102f82:	c7 04 24 ed 59 10 f0 	movl   $0xf01059ed,(%esp)
f0102f89:	e8 38 d1 ff ff       	call   f01000c6 <_panic>
	return &pages[PGNUM(pa)];
f0102f8e:	8b 15 8c 6f 18 f0    	mov    0xf0186f8c,%edx
f0102f94:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0102f97:	c3                   	ret    

f0102f98 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f98:	55                   	push   %ebp
f0102f99:	89 e5                	mov    %esp,%ebp
f0102f9b:	57                   	push   %edi
f0102f9c:	56                   	push   %esi
f0102f9d:	53                   	push   %ebx
f0102f9e:	83 ec 2c             	sub    $0x2c,%esp
f0102fa1:	89 c7                	mov    %eax,%edi
f0102fa3:	89 d3                	mov    %edx,%ebx
f0102fa5:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	cprintf("Entro a region_alloc.\nenv_pgdir es: %p\n", e->env_pgdir);
f0102fa8:	8b 40 5c             	mov    0x5c(%eax),%eax
f0102fab:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102faf:	c7 04 24 2c 5d 10 f0 	movl   $0xf0105d2c,(%esp)
f0102fb6:	e8 a7 08 00 00       	call   f0103862 <cprintf>
	va = ROUNDDOWN(va,PGSIZE);
f0102fbb:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102fc1:	89 de                	mov    %ebx,%esi
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f0102fc3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fc6:	8d 84 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%eax
f0102fcd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102fd2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cprintf("checkpoint\n");//DEBUG2
f0102fd5:	c7 04 24 d7 5e 10 f0 	movl   $0xf0105ed7,(%esp)
f0102fdc:	e8 81 08 00 00       	call   f0103862 <cprintf>
	if (va_finish>va) {
f0102fe1:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102fe4:	73 18                	jae    f0102ffe <region_alloc+0x66>
		len = va_finish - va; //es un multiplo de PGSIZE	
f0102fe6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fe9:	29 d8                	sub    %ebx,%eax
f0102feb:	89 c3                	mov    %eax,%ebx
		cprintf("FLAGTRUE\n");//DEBUG2
f0102fed:	c7 04 24 e3 5e 10 f0 	movl   $0xf0105ee3,(%esp)
f0102ff4:	e8 69 08 00 00       	call   f0103862 <cprintf>
f0102ff9:	e9 84 00 00 00       	jmp    f0103082 <region_alloc+0xea>
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
f0102ffe:	f7 db                	neg    %ebx
		cprintf("FLAGFALSE\n");//DEBUG2
f0103000:	c7 04 24 ed 5e 10 f0 	movl   $0xf0105eed,(%esp)
f0103007:	e8 56 08 00 00       	call   f0103862 <cprintf>
f010300c:	eb 74                	jmp    f0103082 <region_alloc+0xea>
	}
	while (len>0){
		struct PageInfo* page = page_alloc(0);//no hay que inicializar
f010300e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103015:	e8 30 e3 ff ff       	call   f010134a <page_alloc>
		if (page == NULL) panic("Error allocating environment");
f010301a:	85 c0                	test   %eax,%eax
f010301c:	75 1c                	jne    f010303a <region_alloc+0xa2>
f010301e:	c7 44 24 08 f8 5e 10 	movl   $0xf0105ef8,0x8(%esp)
f0103025:	f0 
f0103026:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
f010302d:	00 
f010302e:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f0103035:	e8 8c d0 ff ff       	call   f01000c6 <_panic>

		int ret_code = page_insert(e->env_pgdir, page, va, PTE_W | PTE_U);
f010303a:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0103041:	00 
f0103042:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103046:	89 44 24 04          	mov    %eax,0x4(%esp)
f010304a:	8b 47 5c             	mov    0x5c(%edi),%eax
f010304d:	89 04 24             	mov    %eax,(%esp)
f0103050:	e8 83 ea ff ff       	call   f0101ad8 <page_insert>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
f0103055:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0103058:	75 1c                	jne    f0103076 <region_alloc+0xde>
f010305a:	c7 44 24 08 f8 5e 10 	movl   $0xf0105ef8,0x8(%esp)
f0103061:	f0 
f0103062:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0103069:	00 
f010306a:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f0103071:	e8 50 d0 ff ff       	call   f01000c6 <_panic>
		
		va+=PGSIZE;
f0103076:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len-=PGSIZE;
f010307c:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
		cprintf("FLAGFALSE\n");//DEBUG2
	}
	while (len>0){
f0103082:	85 db                	test   %ebx,%ebx
f0103084:	75 88                	jne    f010300e <region_alloc+0x76>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
		
		va+=PGSIZE;
		len-=PGSIZE;
	}
	assert(va==va_finish);
f0103086:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0103089:	74 24                	je     f01030af <region_alloc+0x117>
f010308b:	c7 44 24 0c 15 5f 10 	movl   $0xf0105f15,0xc(%esp)
f0103092:	f0 
f0103093:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010309a:	f0 
f010309b:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
f01030a2:	00 
f01030a3:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f01030aa:	e8 17 d0 ff ff       	call   f01000c6 <_panic>
	cprintf("Salgo de region_alloc.\nenv_pgdir es: %p\n", e->env_pgdir);
f01030af:	8b 47 5c             	mov    0x5c(%edi),%eax
f01030b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030b6:	c7 04 24 54 5d 10 f0 	movl   $0xf0105d54,(%esp)
f01030bd:	e8 a0 07 00 00       	call   f0103862 <cprintf>
}
f01030c2:	83 c4 2c             	add    $0x2c,%esp
f01030c5:	5b                   	pop    %ebx
f01030c6:	5e                   	pop    %esi
f01030c7:	5f                   	pop    %edi
f01030c8:	5d                   	pop    %ebp
f01030c9:	c3                   	ret    

f01030ca <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f01030ca:	55                   	push   %ebp
f01030cb:	89 e5                	mov    %esp,%ebp
f01030cd:	57                   	push   %edi
f01030ce:	56                   	push   %esi
f01030cf:	53                   	push   %ebx
f01030d0:	83 ec 2c             	sub    $0x2c,%esp
f01030d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01030d6:	89 d6                	mov    %edx,%esi
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	

	cprintf("Entro a load_icode.\nrcr3 da %p,kern_pgdir es %p, env_pgdir es %p\n",(void*)rcr3(),kern_pgdir,e->env_pgdir);//DEBUG2
f01030d8:	8b 78 5c             	mov    0x5c(%eax),%edi
f01030db:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f01030e1:	e8 6c fd ff ff       	call   f0102e52 <rcr3>
f01030e6:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01030ea:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01030ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030f2:	c7 04 24 80 5d 10 f0 	movl   $0xf0105d80,(%esp)
f01030f9:	e8 64 07 00 00       	call   f0103862 <cprintf>
	assert(rcr3()==PADDR(kern_pgdir));
f01030fe:	e8 4f fd ff ff       	call   f0102e52 <rcr3>
f0103103:	89 c3                	mov    %eax,%ebx
f0103105:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f010310b:	ba 68 01 00 00       	mov    $0x168,%edx
f0103110:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f0103115:	e8 a7 fd ff ff       	call   f0102ec1 <_paddr>
f010311a:	39 c3                	cmp    %eax,%ebx
f010311c:	74 24                	je     f0103142 <load_icode+0x78>
f010311e:	c7 44 24 0c 23 5f 10 	movl   $0xf0105f23,0xc(%esp)
f0103125:	f0 
f0103126:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f010312d:	f0 
f010312e:	c7 44 24 04 68 01 00 	movl   $0x168,0x4(%esp)
f0103135:	00 
f0103136:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f010313d:	e8 84 cf ff ff       	call   f01000c6 <_panic>
	lcr3(PADDR(e->env_pgdir));//cambio a pgdir del env para que anden memcpy y memset
f0103142:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103145:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f0103148:	ba 69 01 00 00       	mov    $0x169,%edx
f010314d:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f0103152:	e8 6a fd ff ff       	call   f0102ec1 <_paddr>
f0103157:	e8 ee fc ff ff       	call   f0102e4a <lcr3>
	cprintf("Modifico cr3.\nrcr3 da %p,kern_pgdir es %p, env_pgdir es %p\n",(void*)rcr3(),kern_pgdir,e->env_pgdir);//DEBUG2
f010315c:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010315f:	8b 7f 5c             	mov    0x5c(%edi),%edi
f0103162:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f0103168:	e8 e5 fc ff ff       	call   f0102e52 <rcr3>
f010316d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103171:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103175:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103179:	c7 04 24 c4 5d 10 f0 	movl   $0xf0105dc4,(%esp)
f0103180:	e8 dd 06 00 00       	call   f0103862 <cprintf>
	assert(rcr3()==PADDR(e->env_pgdir));
f0103185:	e8 c8 fc ff ff       	call   f0102e52 <rcr3>
f010318a:	89 c3                	mov    %eax,%ebx
f010318c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010318f:	8b 48 5c             	mov    0x5c(%eax),%ecx
f0103192:	ba 6b 01 00 00       	mov    $0x16b,%edx
f0103197:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f010319c:	e8 20 fd ff ff       	call   f0102ec1 <_paddr>
f01031a1:	39 c3                	cmp    %eax,%ebx
f01031a3:	74 24                	je     f01031c9 <load_icode+0xff>
f01031a5:	c7 44 24 0c 3d 5f 10 	movl   $0xf0105f3d,0xc(%esp)
f01031ac:	f0 
f01031ad:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f01031b4:	f0 
f01031b5:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
f01031bc:	00 
f01031bd:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f01031c4:	e8 fd ce ff ff       	call   f01000c6 <_panic>

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f01031c9:	81 3e 7f 45 4c 46    	cmpl   $0x464c457f,(%esi)
f01031cf:	74 1c                	je     f01031ed <load_icode+0x123>
f01031d1:	c7 44 24 08 59 5f 10 	movl   $0xf0105f59,0x8(%esp)
f01031d8:	f0 
f01031d9:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f01031e0:	00 
f01031e1:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f01031e8:	e8 d9 ce ff ff       	call   f01000c6 <_panic>

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f01031ed:	89 f3                	mov    %esi,%ebx
f01031ef:	03 5e 1c             	add    0x1c(%esi),%ebx
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f01031f2:	bf 00 00 00 00       	mov    $0x0,%edi
f01031f7:	e9 f7 00 00 00       	jmp    f01032f3 <load_icode+0x229>
		va=(void*) ph->p_va;
f01031fc:	8b 43 08             	mov    0x8(%ebx),%eax
f01031ff:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if (ph->p_type != ELF_PROG_LOAD) continue;
f0103202:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103205:	0f 85 e5 00 00 00    	jne    f01032f0 <load_icode+0x226>
		region_alloc(e,va,ph->p_memsz);
f010320b:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010320e:	89 c2                	mov    %eax,%edx
f0103210:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103213:	e8 80 fd ff ff       	call   f0102f98 <region_alloc>
		cprintf("\tVA es %p\n",va);//DEBUG2
f0103218:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010321b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010321f:	c7 04 24 68 5f 10 f0 	movl   $0xf0105f68,(%esp)
f0103226:	e8 37 06 00 00       	call   f0103862 <cprintf>
		cprintf("\tbinary es %p\n",binary);//DEBUG2
f010322b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010322f:	c7 04 24 73 5f 10 f0 	movl   $0xf0105f73,(%esp)
f0103236:	e8 27 06 00 00       	call   f0103862 <cprintf>
		cprintf("\tph es %p\n",ph);//DEBUG2
f010323b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010323f:	c7 04 24 82 5f 10 f0 	movl   $0xf0105f82,(%esp)
f0103246:	e8 17 06 00 00       	call   f0103862 <cprintf>
		cprintf("\tp_offset es %p\n",ph->p_offset);//DEBUG2
f010324b:	8b 43 04             	mov    0x4(%ebx),%eax
f010324e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103252:	c7 04 24 8d 5f 10 f0 	movl   $0xf0105f8d,(%esp)
f0103259:	e8 04 06 00 00       	call   f0103862 <cprintf>
		cprintf("\tbin+p_off es %p\n",(void*)binary+ph->p_offset);//DEBUG2
f010325e:	89 f2                	mov    %esi,%edx
f0103260:	03 53 04             	add    0x4(%ebx),%edx
f0103263:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103267:	c7 04 24 9e 5f 10 f0 	movl   $0xf0105f9e,(%esp)
f010326e:	e8 ef 05 00 00       	call   f0103862 <cprintf>
		cprintf("\tfilesz es %d y memsz es %d\n",ph->p_filesz,ph->p_memsz);//DEBUG2
f0103273:	8b 43 14             	mov    0x14(%ebx),%eax
f0103276:	89 44 24 08          	mov    %eax,0x8(%esp)
f010327a:	8b 43 10             	mov    0x10(%ebx),%eax
f010327d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103281:	c7 04 24 b0 5f 10 f0 	movl   $0xf0105fb0,(%esp)
f0103288:	e8 d5 05 00 00       	call   f0103862 <cprintf>
		cprintf("\tentsize es %d\n",elf->e_phentsize);//DEBUG2
f010328d:	0f b7 46 2a          	movzwl 0x2a(%esi),%eax
f0103291:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103295:	c7 04 24 cd 5f 10 f0 	movl   $0xf0105fcd,(%esp)
f010329c:	e8 c1 05 00 00       	call   f0103862 <cprintf>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);
f01032a1:	8b 43 10             	mov    0x10(%ebx),%eax
f01032a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01032a8:	89 f1                	mov    %esi,%ecx
f01032aa:	03 4b 04             	add    0x4(%ebx),%ecx
f01032ad:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01032b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032b4:	89 04 24             	mov    %eax,(%esp)
f01032b7:	e8 21 16 00 00       	call   f01048dd <memcpy>
		cprintf("\thizo el memcpy\n");//DEBUG2
f01032bc:	c7 04 24 dd 5f 10 f0 	movl   $0xf0105fdd,(%esp)
f01032c3:	e8 9a 05 00 00       	call   f0103862 <cprintf>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f01032c8:	8b 43 10             	mov    0x10(%ebx),%eax
f01032cb:	8b 53 14             	mov    0x14(%ebx),%edx
f01032ce:	29 c2                	sub    %eax,%edx
f01032d0:	89 54 24 08          	mov    %edx,0x8(%esp)
f01032d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032db:	00 
f01032dc:	03 45 e4             	add    -0x1c(%ebp),%eax
f01032df:	89 04 24             	mov    %eax,(%esp)
f01032e2:	e8 40 15 00 00       	call   f0104827 <memset>
		ph += elf->e_phentsize;
f01032e7:	0f b7 46 2a          	movzwl 0x2a(%esi),%eax
f01032eb:	c1 e0 05             	shl    $0x5,%eax
f01032ee:	01 c3                	add    %eax,%ebx
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f01032f0:	83 c7 01             	add    $0x1,%edi
f01032f3:	0f b7 46 2c          	movzwl 0x2c(%esi),%eax
f01032f7:	39 c7                	cmp    %eax,%edi
f01032f9:	0f 8c fd fe ff ff    	jl     f01031fc <load_icode+0x132>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
		ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f01032ff:	8b 46 18             	mov    0x18(%esi),%eax
f0103302:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103305:	89 46 30             	mov    %eax,0x30(%esi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)USTACKTOP - PGSIZE,PGSIZE);
f0103308:	b9 00 10 00 00       	mov    $0x1000,%ecx
f010330d:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103312:	89 f0                	mov    %esi,%eax
f0103314:	e8 7f fc ff ff       	call   f0102f98 <region_alloc>

	lcr3(PADDR(kern_pgdir));//vuelvo a poner el pgdir del kernel 
f0103319:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f010331f:	ba 8d 01 00 00       	mov    $0x18d,%edx
f0103324:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f0103329:	e8 93 fb ff ff       	call   f0102ec1 <_paddr>
f010332e:	e8 17 fb ff ff       	call   f0102e4a <lcr3>
	cprintf("Salgo de load_icode.\nrcr3 da %p,kern_pgdir es %p, env_pgdir es %p\n",(void*)rcr3(),kern_pgdir,e->env_pgdir);//DEBUG2
f0103333:	8b 76 5c             	mov    0x5c(%esi),%esi
f0103336:	8b 1d 88 6f 18 f0    	mov    0xf0186f88,%ebx
f010333c:	e8 11 fb ff ff       	call   f0102e52 <rcr3>
f0103341:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103345:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103349:	89 44 24 04          	mov    %eax,0x4(%esp)
f010334d:	c7 04 24 00 5e 10 f0 	movl   $0xf0105e00,(%esp)
f0103354:	e8 09 05 00 00       	call   f0103862 <cprintf>
}
f0103359:	83 c4 2c             	add    $0x2c,%esp
f010335c:	5b                   	pop    %ebx
f010335d:	5e                   	pop    %esi
f010335e:	5f                   	pop    %edi
f010335f:	5d                   	pop    %ebp
f0103360:	c3                   	ret    

f0103361 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103361:	55                   	push   %ebp
f0103362:	89 e5                	mov    %esp,%ebp
f0103364:	8b 45 08             	mov    0x8(%ebp),%eax
f0103367:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010336a:	85 c0                	test   %eax,%eax
f010336c:	75 11                	jne    f010337f <envid2env+0x1e>
		*env_store = curenv;
f010336e:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103373:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103376:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103378:	b8 00 00 00 00       	mov    $0x0,%eax
f010337d:	eb 5e                	jmp    f01033dd <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010337f:	89 c2                	mov    %eax,%edx
f0103381:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103387:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010338a:	c1 e2 05             	shl    $0x5,%edx
f010338d:	03 15 c8 52 18 f0    	add    0xf01852c8,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103393:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103397:	74 05                	je     f010339e <envid2env+0x3d>
f0103399:	39 42 48             	cmp    %eax,0x48(%edx)
f010339c:	74 10                	je     f01033ae <envid2env+0x4d>
		*env_store = 0;
f010339e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033a1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01033a7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01033ac:	eb 2f                	jmp    f01033dd <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01033ae:	84 c9                	test   %cl,%cl
f01033b0:	74 21                	je     f01033d3 <envid2env+0x72>
f01033b2:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01033b7:	39 c2                	cmp    %eax,%edx
f01033b9:	74 18                	je     f01033d3 <envid2env+0x72>
f01033bb:	8b 40 48             	mov    0x48(%eax),%eax
f01033be:	39 42 4c             	cmp    %eax,0x4c(%edx)
f01033c1:	74 10                	je     f01033d3 <envid2env+0x72>
		*env_store = 0;
f01033c3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033c6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01033cc:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01033d1:	eb 0a                	jmp    f01033dd <envid2env+0x7c>
	}

	*env_store = e;
f01033d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033d6:	89 10                	mov    %edx,(%eax)
	return 0;
f01033d8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01033dd:	5d                   	pop    %ebp
f01033de:	c3                   	ret    

f01033df <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01033df:	55                   	push   %ebp
f01033e0:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f01033e2:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f01033e7:	e8 4e fa ff ff       	call   f0102e3a <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f01033ec:	b8 23 00 00 00       	mov    $0x23,%eax
f01033f1:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f01033f3:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f01033f5:	b0 10                	mov    $0x10,%al
f01033f7:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f01033f9:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f01033fb:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f01033fd:	ea 04 34 10 f0 08 00 	ljmp   $0x8,$0xf0103404
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f0103404:	b0 00                	mov    $0x0,%al
f0103406:	e8 37 fa ff ff       	call   f0102e42 <lldt>
}
f010340b:	5d                   	pop    %ebp
f010340c:	c3                   	ret    

f010340d <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010340d:	55                   	push   %ebp
f010340e:	89 e5                	mov    %esp,%ebp
f0103410:	56                   	push   %esi
f0103411:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here. (OK)
	for (size_t i=0; i< NENV; i++){
		envs[i].env_status = ENV_FREE; 
f0103412:	8b 35 c8 52 18 f0    	mov    0xf01852c8,%esi
f0103418:	8b 0d cc 52 18 f0    	mov    0xf01852cc,%ecx
f010341e:	89 f0                	mov    %esi,%eax
f0103420:	ba 00 04 00 00       	mov    $0x400,%edx
f0103425:	89 c3                	mov    %eax,%ebx
f0103427:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_id = 0;
f010342e:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = env_free_list;
f0103435:	89 48 44             	mov    %ecx,0x44(%eax)
f0103438:	83 c0 60             	add    $0x60,%eax
void
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	for (size_t i=0; i< NENV; i++){
f010343b:	83 ea 01             	sub    $0x1,%edx
f010343e:	74 04                	je     f0103444 <env_init+0x37>
		envs[i].env_status = ENV_FREE; 
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
f0103440:	89 d9                	mov    %ebx,%ecx
f0103442:	eb e1                	jmp    f0103425 <env_init+0x18>
f0103444:	81 c6 a0 7f 01 00    	add    $0x17fa0,%esi
f010344a:	89 35 cc 52 18 f0    	mov    %esi,0xf01852cc
	}

	// Per-CPU part of the initialization
	env_init_percpu();
f0103450:	e8 8a ff ff ff       	call   f01033df <env_init_percpu>
}
f0103455:	5b                   	pop    %ebx
f0103456:	5e                   	pop    %esi
f0103457:	5d                   	pop    %ebp
f0103458:	c3                   	ret    

f0103459 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103459:	55                   	push   %ebp
f010345a:	89 e5                	mov    %esp,%ebp
f010345c:	53                   	push   %ebx
f010345d:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103460:	8b 1d cc 52 18 f0    	mov    0xf01852cc,%ebx
f0103466:	85 db                	test   %ebx,%ebx
f0103468:	0f 84 ca 00 00 00    	je     f0103538 <env_alloc+0xdf>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f010346e:	89 d8                	mov    %ebx,%eax
f0103470:	e8 79 fa ff ff       	call   f0102eee <env_setup_vm>
f0103475:	85 c0                	test   %eax,%eax
f0103477:	0f 88 c0 00 00 00    	js     f010353d <env_alloc+0xe4>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010347d:	8b 43 48             	mov    0x48(%ebx),%eax
f0103480:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f0103485:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f010348a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010348f:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103492:	89 da                	mov    %ebx,%edx
f0103494:	2b 15 c8 52 18 f0    	sub    0xf01852c8,%edx
f010349a:	c1 fa 05             	sar    $0x5,%edx
f010349d:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01034a3:	09 d0                	or     %edx,%eax
f01034a5:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01034a8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034ab:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01034ae:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01034b5:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01034bc:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01034c3:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01034ca:	00 
f01034cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01034d2:	00 
f01034d3:	89 1c 24             	mov    %ebx,(%esp)
f01034d6:	e8 4c 13 00 00       	call   f0104827 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01034db:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01034e1:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01034e7:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01034ed:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01034f4:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01034fa:	8b 43 44             	mov    0x44(%ebx),%eax
f01034fd:	a3 cc 52 18 f0       	mov    %eax,0xf01852cc
	*newenv_store = e; 
f0103502:	8b 45 08             	mov    0x8(%ebp),%eax
f0103505:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103507:	8b 53 48             	mov    0x48(%ebx),%edx
f010350a:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010350f:	85 c0                	test   %eax,%eax
f0103511:	74 05                	je     f0103518 <env_alloc+0xbf>
f0103513:	8b 40 48             	mov    0x48(%eax),%eax
f0103516:	eb 05                	jmp    f010351d <env_alloc+0xc4>
f0103518:	b8 00 00 00 00       	mov    $0x0,%eax
f010351d:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103521:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103525:	c7 04 24 ee 5f 10 f0 	movl   $0xf0105fee,(%esp)
f010352c:	e8 31 03 00 00       	call   f0103862 <cprintf>
	return 0;
f0103531:	b8 00 00 00 00       	mov    $0x0,%eax
f0103536:	eb 05                	jmp    f010353d <env_alloc+0xe4>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103538:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f010353d:	83 c4 14             	add    $0x14,%esp
f0103540:	5b                   	pop    %ebx
f0103541:	5d                   	pop    %ebp
f0103542:	c3                   	ret    

f0103543 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103543:	55                   	push   %ebp
f0103544:	89 e5                	mov    %esp,%ebp
f0103546:	83 ec 28             	sub    $0x28,%esp
	// LAB 3: Your code here.
	cprintf("Entro a env_create\n");
f0103549:	c7 04 24 03 60 10 f0 	movl   $0xf0106003,(%esp)
f0103550:	e8 0d 03 00 00       	call   f0103862 <cprintf>
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f0103555:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010355c:	00 
f010355d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103560:	89 04 24             	mov    %eax,(%esp)
f0103563:	e8 f1 fe ff ff       	call   f0103459 <env_alloc>
	if (err<0) panic("env_create: %e", err);
f0103568:	85 c0                	test   %eax,%eax
f010356a:	79 20                	jns    f010358c <env_create+0x49>
f010356c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103570:	c7 44 24 08 17 60 10 	movl   $0xf0106017,0x8(%esp)
f0103577:	f0 
f0103578:	c7 44 24 04 9f 01 00 	movl   $0x19f,0x4(%esp)
f010357f:	00 
f0103580:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f0103587:	e8 3a cb ff ff       	call   f01000c6 <_panic>
	load_icode(e,binary);
f010358c:	8b 55 08             	mov    0x8(%ebp),%edx
f010358f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103592:	e8 33 fb ff ff       	call   f01030ca <load_icode>
	e->env_type = type;
f0103597:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010359a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010359d:	89 50 50             	mov    %edx,0x50(%eax)
	cprintf("Salgo de env_create.env_pgdir es: %p\n", e->env_pgdir);
f01035a0:	8b 40 5c             	mov    0x5c(%eax),%eax
f01035a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035a7:	c7 04 24 44 5e 10 f0 	movl   $0xf0105e44,(%esp)
f01035ae:	e8 af 02 00 00       	call   f0103862 <cprintf>
}
f01035b3:	c9                   	leave  
f01035b4:	c3                   	ret    

f01035b5 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01035b5:	55                   	push   %ebp
f01035b6:	89 e5                	mov    %esp,%ebp
f01035b8:	57                   	push   %edi
f01035b9:	56                   	push   %esi
f01035ba:	53                   	push   %ebx
f01035bb:	83 ec 2c             	sub    $0x2c,%esp
f01035be:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01035c1:	3b 3d c4 52 18 f0    	cmp    0xf01852c4,%edi
f01035c7:	75 1a                	jne    f01035e3 <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f01035c9:	8b 0d 88 6f 18 f0    	mov    0xf0186f88,%ecx
f01035cf:	ba b3 01 00 00       	mov    $0x1b3,%edx
f01035d4:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f01035d9:	e8 e3 f8 ff ff       	call   f0102ec1 <_paddr>
f01035de:	e8 67 f8 ff ff       	call   f0102e4a <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01035e3:	8b 57 48             	mov    0x48(%edi),%edx
f01035e6:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01035eb:	85 c0                	test   %eax,%eax
f01035ed:	74 05                	je     f01035f4 <env_free+0x3f>
f01035ef:	8b 40 48             	mov    0x48(%eax),%eax
f01035f2:	eb 05                	jmp    f01035f9 <env_free+0x44>
f01035f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01035f9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01035fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103601:	c7 04 24 26 60 10 f0 	movl   $0xf0106026,(%esp)
f0103608:	e8 55 02 00 00       	call   f0103862 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010360d:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103614:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103617:	89 d0                	mov    %edx,%eax
f0103619:	c1 e0 02             	shl    $0x2,%eax
f010361c:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010361f:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103622:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0103625:	a8 01                	test   $0x1,%al
f0103627:	74 6e                	je     f0103697 <env_free+0xe2>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103629:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010362e:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f0103631:	89 c1                	mov    %eax,%ecx
f0103633:	ba c1 01 00 00       	mov    $0x1c1,%edx
f0103638:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f010363d:	e8 29 f8 ff ff       	call   f0102e6b <_kaddr>
f0103642:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103644:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103647:	c1 e0 16             	shl    $0x16,%eax
f010364a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010364d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103652:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f0103656:	74 17                	je     f010366f <env_free+0xba>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103658:	89 d8                	mov    %ebx,%eax
f010365a:	c1 e0 0c             	shl    $0xc,%eax
f010365d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103660:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103664:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103667:	89 04 24             	mov    %eax,(%esp)
f010366a:	e8 20 e4 ff ff       	call   f0101a8f <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010366f:	83 c3 01             	add    $0x1,%ebx
f0103672:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103678:	75 d8                	jne    f0103652 <env_free+0x9d>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010367a:	8b 47 5c             	mov    0x5c(%edi),%eax
f010367d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0103680:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f0103687:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010368a:	e8 d2 f8 ff ff       	call   f0102f61 <pa2page>
f010368f:	89 04 24             	mov    %eax,(%esp)
f0103692:	e8 fa e1 ff ff       	call   f0101891 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103697:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010369b:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f01036a2:	0f 85 6c ff ff ff    	jne    f0103614 <env_free+0x5f>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01036a8:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f01036ab:	ba cf 01 00 00       	mov    $0x1cf,%edx
f01036b0:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f01036b5:	e8 07 f8 ff ff       	call   f0102ec1 <_paddr>
	e->env_pgdir = 0;
f01036ba:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f01036c1:	e8 9b f8 ff ff       	call   f0102f61 <pa2page>
f01036c6:	89 04 24             	mov    %eax,(%esp)
f01036c9:	e8 c3 e1 ff ff       	call   f0101891 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01036ce:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01036d5:	a1 cc 52 18 f0       	mov    0xf01852cc,%eax
f01036da:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01036dd:	89 3d cc 52 18 f0    	mov    %edi,0xf01852cc
}
f01036e3:	83 c4 2c             	add    $0x2c,%esp
f01036e6:	5b                   	pop    %ebx
f01036e7:	5e                   	pop    %esi
f01036e8:	5f                   	pop    %edi
f01036e9:	5d                   	pop    %ebp
f01036ea:	c3                   	ret    

f01036eb <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01036eb:	55                   	push   %ebp
f01036ec:	89 e5                	mov    %esp,%ebp
f01036ee:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01036f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f4:	89 04 24             	mov    %eax,(%esp)
f01036f7:	e8 b9 fe ff ff       	call   f01035b5 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01036fc:	c7 04 24 6c 5e 10 f0 	movl   $0xf0105e6c,(%esp)
f0103703:	e8 5a 01 00 00       	call   f0103862 <cprintf>
	while (1)
		monitor(NULL);
f0103708:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010370f:	e8 40 d3 ff ff       	call   f0100a54 <monitor>
f0103714:	eb f2                	jmp    f0103708 <env_destroy+0x1d>

f0103716 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103716:	55                   	push   %ebp
f0103717:	89 e5                	mov    %esp,%ebp
f0103719:	83 ec 18             	sub    $0x18,%esp
	asm volatile("\tmovl %0,%%esp\n"
f010371c:	8b 65 08             	mov    0x8(%ebp),%esp
f010371f:	61                   	popa   
f0103720:	07                   	pop    %es
f0103721:	1f                   	pop    %ds
f0103722:	83 c4 08             	add    $0x8,%esp
f0103725:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f0103726:	c7 44 24 08 3c 60 10 	movl   $0xf010603c,0x8(%esp)
f010372d:	f0 
f010372e:	c7 44 24 04 f9 01 00 	movl   $0x1f9,0x4(%esp)
f0103735:	00 
f0103736:	c7 04 24 cc 5e 10 f0 	movl   $0xf0105ecc,(%esp)
f010373d:	e8 84 c9 ff ff       	call   f01000c6 <_panic>

f0103742 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103742:	55                   	push   %ebp
f0103743:	89 e5                	mov    %esp,%ebp
f0103745:	53                   	push   %ebx
f0103746:	83 ec 14             	sub    $0x14,%esp
f0103749:	8b 5d 08             	mov    0x8(%ebp),%ebx

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f010374c:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103751:	85 c0                	test   %eax,%eax
f0103753:	74 25                	je     f010377a <env_run+0x38>
		cprintf("Estoy en un proc y su env_status es %d\n",curenv->env_status);//DEBUG2
f0103755:	8b 40 54             	mov    0x54(%eax),%eax
f0103758:	89 44 24 04          	mov    %eax,0x4(%esp)
f010375c:	c7 04 24 a4 5e 10 f0 	movl   $0xf0105ea4,(%esp)
f0103763:	e8 fa 00 00 00       	call   f0103862 <cprintf>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f0103768:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f010376d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103771:	75 07                	jne    f010377a <env_run+0x38>
f0103773:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	//assert(e->env_status != ENV_FREE);//DEBUG2
	//assert(e->env_status == ENV_RUNNABLE);//DEBUG2
	curenv=e;
f010377a:	89 1d c4 52 18 f0    	mov    %ebx,0xf01852c4
	curenv->env_status = ENV_RUNNING;
f0103780:	c7 43 54 03 00 00 00 	movl   $0x3,0x54(%ebx)
	curenv->env_runs++;
f0103787:	83 43 58 01          	addl   $0x1,0x58(%ebx)
	cprintf("env_pgdir es %p",e->env_pgdir);
f010378b:	8b 43 5c             	mov    0x5c(%ebx),%eax
f010378e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103792:	c7 04 24 48 60 10 f0 	movl   $0xf0106048,(%esp)
f0103799:	e8 c4 00 00 00       	call   f0103862 <cprintf>
	lcr3(PADDR(curenv->env_pgdir));
f010379e:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01037a3:	8b 48 5c             	mov    0x5c(%eax),%ecx
f01037a6:	ba 29 02 00 00       	mov    $0x229,%edx
f01037ab:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f01037b0:	e8 0c f7 ff ff       	call   f0102ec1 <_paddr>
f01037b5:	e8 90 f6 ff ff       	call   f0102e4a <lcr3>
	env_pop_tf(&(curenv->env_tf));
f01037ba:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f01037bf:	89 04 24             	mov    %eax,(%esp)
f01037c2:	e8 4f ff ff ff       	call   f0103716 <env_pop_tf>

f01037c7 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f01037c7:	55                   	push   %ebp
f01037c8:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01037ca:	89 c2                	mov    %eax,%edx
f01037cc:	ec                   	in     (%dx),%al
	return data;
}
f01037cd:	5d                   	pop    %ebp
f01037ce:	c3                   	ret    

f01037cf <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f01037cf:	55                   	push   %ebp
f01037d0:	89 e5                	mov    %esp,%ebp
f01037d2:	89 c1                	mov    %eax,%ecx
f01037d4:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01037d6:	89 ca                	mov    %ecx,%edx
f01037d8:	ee                   	out    %al,(%dx)
}
f01037d9:	5d                   	pop    %ebp
f01037da:	c3                   	ret    

f01037db <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01037db:	55                   	push   %ebp
f01037dc:	89 e5                	mov    %esp,%ebp
f01037de:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f01037e2:	b8 70 00 00 00       	mov    $0x70,%eax
f01037e7:	e8 e3 ff ff ff       	call   f01037cf <outb>
	return inb(IO_RTC+1);
f01037ec:	b8 71 00 00 00       	mov    $0x71,%eax
f01037f1:	e8 d1 ff ff ff       	call   f01037c7 <inb>
f01037f6:	0f b6 c0             	movzbl %al,%eax
}
f01037f9:	5d                   	pop    %ebp
f01037fa:	c3                   	ret    

f01037fb <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01037fb:	55                   	push   %ebp
f01037fc:	89 e5                	mov    %esp,%ebp
f01037fe:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f0103802:	b8 70 00 00 00       	mov    $0x70,%eax
f0103807:	e8 c3 ff ff ff       	call   f01037cf <outb>
f010380c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
	outb(IO_RTC+1, datum);
f0103810:	b8 71 00 00 00       	mov    $0x71,%eax
f0103815:	e8 b5 ff ff ff       	call   f01037cf <outb>
}
f010381a:	5d                   	pop    %ebp
f010381b:	c3                   	ret    

f010381c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010381c:	55                   	push   %ebp
f010381d:	89 e5                	mov    %esp,%ebp
f010381f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103822:	8b 45 08             	mov    0x8(%ebp),%eax
f0103825:	89 04 24             	mov    %eax,(%esp)
f0103828:	e8 1b cf ff ff       	call   f0100748 <cputchar>
	*cnt++;
}
f010382d:	c9                   	leave  
f010382e:	c3                   	ret    

f010382f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010382f:	55                   	push   %ebp
f0103830:	89 e5                	mov    %esp,%ebp
f0103832:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103835:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010383c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010383f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103843:	8b 45 08             	mov    0x8(%ebp),%eax
f0103846:	89 44 24 08          	mov    %eax,0x8(%esp)
f010384a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010384d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103851:	c7 04 24 1c 38 10 f0 	movl   $0xf010381c,(%esp)
f0103858:	e8 63 09 00 00       	call   f01041c0 <vprintfmt>
	return cnt;
}
f010385d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103860:	c9                   	leave  
f0103861:	c3                   	ret    

f0103862 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103862:	55                   	push   %ebp
f0103863:	89 e5                	mov    %esp,%ebp
f0103865:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103868:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010386b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010386f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103872:	89 04 24             	mov    %eax,(%esp)
f0103875:	e8 b5 ff ff ff       	call   f010382f <vcprintf>
	va_end(ap);

	return cnt;
}
f010387a:	c9                   	leave  
f010387b:	c3                   	ret    

f010387c <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f010387c:	55                   	push   %ebp
f010387d:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f010387f:	0f 01 18             	lidtl  (%eax)
}
f0103882:	5d                   	pop    %ebp
f0103883:	c3                   	ret    

f0103884 <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f0103884:	55                   	push   %ebp
f0103885:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f0103887:	0f 00 d8             	ltr    %ax
}
f010388a:	5d                   	pop    %ebp
f010388b:	c3                   	ret    

f010388c <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f010388c:	55                   	push   %ebp
f010388d:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010388f:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f0103892:	5d                   	pop    %ebp
f0103893:	c3                   	ret    

f0103894 <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f0103894:	55                   	push   %ebp
f0103895:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103897:	9c                   	pushf  
f0103898:	58                   	pop    %eax
	return eflags;
}
f0103899:	5d                   	pop    %ebp
f010389a:	c3                   	ret    

f010389b <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f010389b:	55                   	push   %ebp
f010389c:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f010389e:	83 f8 13             	cmp    $0x13,%eax
f01038a1:	77 09                	ja     f01038ac <trapname+0x11>
		return excnames[trapno];
f01038a3:	8b 04 85 c0 63 10 f0 	mov    -0xfef9c40(,%eax,4),%eax
f01038aa:	eb 10                	jmp    f01038bc <trapname+0x21>
	if (trapno == T_SYSCALL)
f01038ac:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
f01038af:	b8 58 60 10 f0       	mov    $0xf0106058,%eax
f01038b4:	ba 64 60 10 f0       	mov    $0xf0106064,%edx
f01038b9:	0f 45 c2             	cmovne %edx,%eax
	return "(unknown trap)";
}
f01038bc:	5d                   	pop    %ebp
f01038bd:	c3                   	ret    

f01038be <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01038be:	55                   	push   %ebp
f01038bf:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01038c1:	c7 05 04 5b 18 f0 00 	movl   $0xf0000000,0xf0185b04
f01038c8:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01038cb:	66 c7 05 08 5b 18 f0 	movw   $0x10,0xf0185b08
f01038d2:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f01038d4:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f01038db:	67 00 
f01038dd:	b8 00 5b 18 f0       	mov    $0xf0185b00,%eax
f01038e2:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f01038e8:	89 c2                	mov    %eax,%edx
f01038ea:	c1 ea 10             	shr    $0x10,%edx
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f01038ed:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f01038f3:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f01038fa:	c1 e8 18             	shr    $0x18,%eax
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f01038fd:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103902:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f0103909:	b8 28 00 00 00       	mov    $0x28,%eax
f010390e:	e8 71 ff ff ff       	call   f0103884 <ltr>

	// Load the IDT
	lidt(&idt_pd);
f0103913:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103918:	e8 5f ff ff ff       	call   f010387c <lidt>
}
f010391d:	5d                   	pop    %ebp
f010391e:	c3                   	ret    

f010391f <trap_init>:
}


void
trap_init(void)
{
f010391f:	55                   	push   %ebp
f0103920:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup
	trap_init_percpu();
f0103922:	e8 97 ff ff ff       	call   f01038be <trap_init_percpu>
}
f0103927:	5d                   	pop    %ebp
f0103928:	c3                   	ret    

f0103929 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103929:	55                   	push   %ebp
f010392a:	89 e5                	mov    %esp,%ebp
f010392c:	53                   	push   %ebx
f010392d:	83 ec 14             	sub    $0x14,%esp
f0103930:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103933:	8b 03                	mov    (%ebx),%eax
f0103935:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103939:	c7 04 24 73 60 10 f0 	movl   $0xf0106073,(%esp)
f0103940:	e8 1d ff ff ff       	call   f0103862 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103945:	8b 43 04             	mov    0x4(%ebx),%eax
f0103948:	89 44 24 04          	mov    %eax,0x4(%esp)
f010394c:	c7 04 24 82 60 10 f0 	movl   $0xf0106082,(%esp)
f0103953:	e8 0a ff ff ff       	call   f0103862 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103958:	8b 43 08             	mov    0x8(%ebx),%eax
f010395b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010395f:	c7 04 24 91 60 10 f0 	movl   $0xf0106091,(%esp)
f0103966:	e8 f7 fe ff ff       	call   f0103862 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010396b:	8b 43 0c             	mov    0xc(%ebx),%eax
f010396e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103972:	c7 04 24 a0 60 10 f0 	movl   $0xf01060a0,(%esp)
f0103979:	e8 e4 fe ff ff       	call   f0103862 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f010397e:	8b 43 10             	mov    0x10(%ebx),%eax
f0103981:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103985:	c7 04 24 af 60 10 f0 	movl   $0xf01060af,(%esp)
f010398c:	e8 d1 fe ff ff       	call   f0103862 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103991:	8b 43 14             	mov    0x14(%ebx),%eax
f0103994:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103998:	c7 04 24 be 60 10 f0 	movl   $0xf01060be,(%esp)
f010399f:	e8 be fe ff ff       	call   f0103862 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01039a4:	8b 43 18             	mov    0x18(%ebx),%eax
f01039a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039ab:	c7 04 24 cd 60 10 f0 	movl   $0xf01060cd,(%esp)
f01039b2:	e8 ab fe ff ff       	call   f0103862 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01039b7:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01039ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039be:	c7 04 24 dc 60 10 f0 	movl   $0xf01060dc,(%esp)
f01039c5:	e8 98 fe ff ff       	call   f0103862 <cprintf>
}
f01039ca:	83 c4 14             	add    $0x14,%esp
f01039cd:	5b                   	pop    %ebx
f01039ce:	5d                   	pop    %ebp
f01039cf:	c3                   	ret    

f01039d0 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01039d0:	55                   	push   %ebp
f01039d1:	89 e5                	mov    %esp,%ebp
f01039d3:	56                   	push   %esi
f01039d4:	53                   	push   %ebx
f01039d5:	83 ec 10             	sub    $0x10,%esp
f01039d8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f01039db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01039df:	c7 04 24 10 62 10 f0 	movl   $0xf0106210,(%esp)
f01039e6:	e8 77 fe ff ff       	call   f0103862 <cprintf>
	print_regs(&tf->tf_regs);
f01039eb:	89 1c 24             	mov    %ebx,(%esp)
f01039ee:	e8 36 ff ff ff       	call   f0103929 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01039f3:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01039f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039fb:	c7 04 24 12 61 10 f0 	movl   $0xf0106112,(%esp)
f0103a02:	e8 5b fe ff ff       	call   f0103862 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a07:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a0f:	c7 04 24 25 61 10 f0 	movl   $0xf0106125,(%esp)
f0103a16:	e8 47 fe ff ff       	call   f0103862 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a1b:	8b 73 28             	mov    0x28(%ebx),%esi
f0103a1e:	89 f0                	mov    %esi,%eax
f0103a20:	e8 76 fe ff ff       	call   f010389b <trapname>
f0103a25:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a29:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103a2d:	c7 04 24 38 61 10 f0 	movl   $0xf0106138,(%esp)
f0103a34:	e8 29 fe ff ff       	call   f0103862 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103a39:	3b 1d e0 5a 18 f0    	cmp    0xf0185ae0,%ebx
f0103a3f:	75 1b                	jne    f0103a5c <print_trapframe+0x8c>
f0103a41:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a45:	75 15                	jne    f0103a5c <print_trapframe+0x8c>
		cprintf("  cr2  0x%08x\n", rcr2());
f0103a47:	e8 40 fe ff ff       	call   f010388c <rcr2>
f0103a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a50:	c7 04 24 4a 61 10 f0 	movl   $0xf010614a,(%esp)
f0103a57:	e8 06 fe ff ff       	call   f0103862 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103a5c:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103a5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a63:	c7 04 24 59 61 10 f0 	movl   $0xf0106159,(%esp)
f0103a6a:	e8 f3 fd ff ff       	call   f0103862 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103a6f:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103a73:	75 51                	jne    f0103ac6 <print_trapframe+0xf6>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f0103a75:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103a78:	89 c2                	mov    %eax,%edx
f0103a7a:	83 e2 01             	and    $0x1,%edx
f0103a7d:	ba eb 60 10 f0       	mov    $0xf01060eb,%edx
f0103a82:	b9 f6 60 10 f0       	mov    $0xf01060f6,%ecx
f0103a87:	0f 45 ca             	cmovne %edx,%ecx
f0103a8a:	89 c2                	mov    %eax,%edx
f0103a8c:	83 e2 02             	and    $0x2,%edx
f0103a8f:	ba 02 61 10 f0       	mov    $0xf0106102,%edx
f0103a94:	be 08 61 10 f0       	mov    $0xf0106108,%esi
f0103a99:	0f 44 d6             	cmove  %esi,%edx
f0103a9c:	83 e0 04             	and    $0x4,%eax
f0103a9f:	b8 0d 61 10 f0       	mov    $0xf010610d,%eax
f0103aa4:	be db 61 10 f0       	mov    $0xf01061db,%esi
f0103aa9:	0f 44 c6             	cmove  %esi,%eax
f0103aac:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103ab0:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103ab4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ab8:	c7 04 24 67 61 10 f0 	movl   $0xf0106167,(%esp)
f0103abf:	e8 9e fd ff ff       	call   f0103862 <cprintf>
f0103ac4:	eb 0c                	jmp    f0103ad2 <print_trapframe+0x102>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103ac6:	c7 04 24 2a 5d 10 f0 	movl   $0xf0105d2a,(%esp)
f0103acd:	e8 90 fd ff ff       	call   f0103862 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103ad2:	8b 43 30             	mov    0x30(%ebx),%eax
f0103ad5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ad9:	c7 04 24 76 61 10 f0 	movl   $0xf0106176,(%esp)
f0103ae0:	e8 7d fd ff ff       	call   f0103862 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ae5:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103ae9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aed:	c7 04 24 85 61 10 f0 	movl   $0xf0106185,(%esp)
f0103af4:	e8 69 fd ff ff       	call   f0103862 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103af9:	8b 43 38             	mov    0x38(%ebx),%eax
f0103afc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b00:	c7 04 24 98 61 10 f0 	movl   $0xf0106198,(%esp)
f0103b07:	e8 56 fd ff ff       	call   f0103862 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103b0c:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103b10:	74 27                	je     f0103b39 <print_trapframe+0x169>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103b12:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103b15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b19:	c7 04 24 a7 61 10 f0 	movl   $0xf01061a7,(%esp)
f0103b20:	e8 3d fd ff ff       	call   f0103862 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103b25:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103b29:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b2d:	c7 04 24 b6 61 10 f0 	movl   $0xf01061b6,(%esp)
f0103b34:	e8 29 fd ff ff       	call   f0103862 <cprintf>
	}
}
f0103b39:	83 c4 10             	add    $0x10,%esp
f0103b3c:	5b                   	pop    %ebx
f0103b3d:	5e                   	pop    %esi
f0103b3e:	5d                   	pop    %ebp
f0103b3f:	c3                   	ret    

f0103b40 <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f0103b40:	55                   	push   %ebp
f0103b41:	89 e5                	mov    %esp,%ebp
f0103b43:	53                   	push   %ebx
f0103b44:	83 ec 14             	sub    $0x14,%esp
f0103b47:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103b49:	89 04 24             	mov    %eax,(%esp)
f0103b4c:	e8 7f fe ff ff       	call   f01039d0 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103b51:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103b56:	75 1c                	jne    f0103b74 <trap_dispatch+0x34>
		panic("unhandled trap in kernel");
f0103b58:	c7 44 24 08 c9 61 10 	movl   $0xf01061c9,0x8(%esp)
f0103b5f:	f0 
f0103b60:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
f0103b67:	00 
f0103b68:	c7 04 24 e2 61 10 f0 	movl   $0xf01061e2,(%esp)
f0103b6f:	e8 52 c5 ff ff       	call   f01000c6 <_panic>
	else {
		env_destroy(curenv);
f0103b74:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103b79:	89 04 24             	mov    %eax,(%esp)
f0103b7c:	e8 6a fb ff ff       	call   f01036eb <env_destroy>
		return;
	}
}
f0103b81:	83 c4 14             	add    $0x14,%esp
f0103b84:	5b                   	pop    %ebx
f0103b85:	5d                   	pop    %ebp
f0103b86:	c3                   	ret    

f0103b87 <trap>:

void
trap(struct Trapframe *tf)
{
f0103b87:	55                   	push   %ebp
f0103b88:	89 e5                	mov    %esp,%ebp
f0103b8a:	57                   	push   %edi
f0103b8b:	56                   	push   %esi
f0103b8c:	83 ec 10             	sub    $0x10,%esp
f0103b8f:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103b92:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103b93:	e8 fc fc ff ff       	call   f0103894 <read_eflags>
f0103b98:	f6 c4 02             	test   $0x2,%ah
f0103b9b:	74 24                	je     f0103bc1 <trap+0x3a>
f0103b9d:	c7 44 24 0c ee 61 10 	movl   $0xf01061ee,0xc(%esp)
f0103ba4:	f0 
f0103ba5:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0103bac:	f0 
f0103bad:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
f0103bb4:	00 
f0103bb5:	c7 04 24 e2 61 10 f0 	movl   $0xf01061e2,(%esp)
f0103bbc:	e8 05 c5 ff ff       	call   f01000c6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103bc1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103bc5:	c7 04 24 07 62 10 f0 	movl   $0xf0106207,(%esp)
f0103bcc:	e8 91 fc ff ff       	call   f0103862 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103bd1:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103bd5:	83 e0 03             	and    $0x3,%eax
f0103bd8:	66 83 f8 03          	cmp    $0x3,%ax
f0103bdc:	75 3c                	jne    f0103c1a <trap+0x93>
		// Trapped from user mode.
		assert(curenv);
f0103bde:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103be3:	85 c0                	test   %eax,%eax
f0103be5:	75 24                	jne    f0103c0b <trap+0x84>
f0103be7:	c7 44 24 0c 22 62 10 	movl   $0xf0106222,0xc(%esp)
f0103bee:	f0 
f0103bef:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0103bf6:	f0 
f0103bf7:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
f0103bfe:	00 
f0103bff:	c7 04 24 e2 61 10 f0 	movl   $0xf01061e2,(%esp)
f0103c06:	e8 bb c4 ff ff       	call   f01000c6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103c0b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103c10:	89 c7                	mov    %eax,%edi
f0103c12:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103c14:	8b 35 c4 52 18 f0    	mov    0xf01852c4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103c1a:	89 35 e0 5a 18 f0    	mov    %esi,0xf0185ae0

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103c20:	89 f0                	mov    %esi,%eax
f0103c22:	e8 19 ff ff ff       	call   f0103b40 <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103c27:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103c2c:	85 c0                	test   %eax,%eax
f0103c2e:	74 06                	je     f0103c36 <trap+0xaf>
f0103c30:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103c34:	74 24                	je     f0103c5a <trap+0xd3>
f0103c36:	c7 44 24 0c 6c 63 10 	movl   $0xf010636c,0xc(%esp)
f0103c3d:	f0 
f0103c3e:	c7 44 24 08 1a 5a 10 	movl   $0xf0105a1a,0x8(%esp)
f0103c45:	f0 
f0103c46:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0103c4d:	00 
f0103c4e:	c7 04 24 e2 61 10 f0 	movl   $0xf01061e2,(%esp)
f0103c55:	e8 6c c4 ff ff       	call   f01000c6 <_panic>
	env_run(curenv);
f0103c5a:	89 04 24             	mov    %eax,(%esp)
f0103c5d:	e8 e0 fa ff ff       	call   f0103742 <env_run>

f0103c62 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103c62:	55                   	push   %ebp
f0103c63:	89 e5                	mov    %esp,%ebp
f0103c65:	53                   	push   %ebx
f0103c66:	83 ec 14             	sub    $0x14,%esp
f0103c69:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103c6c:	e8 1b fc ff ff       	call   f010388c <rcr2>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c71:	8b 53 30             	mov    0x30(%ebx),%edx
f0103c74:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c78:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c7c:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103c81:	8b 40 48             	mov    0x48(%eax),%eax
f0103c84:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c88:	c7 04 24 98 63 10 f0 	movl   $0xf0106398,(%esp)
f0103c8f:	e8 ce fb ff ff       	call   f0103862 <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f0103c94:	89 1c 24             	mov    %ebx,(%esp)
f0103c97:	e8 34 fd ff ff       	call   f01039d0 <print_trapframe>
	env_destroy(curenv);
f0103c9c:	a1 c4 52 18 f0       	mov    0xf01852c4,%eax
f0103ca1:	89 04 24             	mov    %eax,(%esp)
f0103ca4:	e8 42 fa ff ff       	call   f01036eb <env_destroy>
}
f0103ca9:	83 c4 14             	add    $0x14,%esp
f0103cac:	5b                   	pop    %ebx
f0103cad:	5d                   	pop    %ebp
f0103cae:	c3                   	ret    

f0103caf <syscall>:
f0103caf:	55                   	push   %ebp
f0103cb0:	89 e5                	mov    %esp,%ebp
f0103cb2:	83 ec 18             	sub    $0x18,%esp
f0103cb5:	c7 44 24 08 10 64 10 	movl   $0xf0106410,0x8(%esp)
f0103cbc:	f0 
f0103cbd:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103cc4:	00 
f0103cc5:	c7 04 24 28 64 10 f0 	movl   $0xf0106428,(%esp)
f0103ccc:	e8 f5 c3 ff ff       	call   f01000c6 <_panic>

f0103cd1 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0103cd1:	55                   	push   %ebp
f0103cd2:	89 e5                	mov    %esp,%ebp
f0103cd4:	57                   	push   %edi
f0103cd5:	56                   	push   %esi
f0103cd6:	53                   	push   %ebx
f0103cd7:	83 ec 14             	sub    $0x14,%esp
f0103cda:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103cdd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103ce0:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103ce3:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103ce6:	8b 1a                	mov    (%edx),%ebx
f0103ce8:	8b 01                	mov    (%ecx),%eax
f0103cea:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103ced:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103cf4:	e9 88 00 00 00       	jmp    f0103d81 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0103cf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103cfc:	01 d8                	add    %ebx,%eax
f0103cfe:	89 c7                	mov    %eax,%edi
f0103d00:	c1 ef 1f             	shr    $0x1f,%edi
f0103d03:	01 c7                	add    %eax,%edi
f0103d05:	d1 ff                	sar    %edi
f0103d07:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103d0a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103d0d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103d10:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103d12:	eb 03                	jmp    f0103d17 <stab_binsearch+0x46>
			m--;
f0103d14:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103d17:	39 c3                	cmp    %eax,%ebx
f0103d19:	7f 1f                	jg     f0103d3a <stab_binsearch+0x69>
f0103d1b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103d1f:	83 ea 0c             	sub    $0xc,%edx
f0103d22:	39 f1                	cmp    %esi,%ecx
f0103d24:	75 ee                	jne    f0103d14 <stab_binsearch+0x43>
f0103d26:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103d29:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103d2c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103d2f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103d33:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103d36:	76 18                	jbe    f0103d50 <stab_binsearch+0x7f>
f0103d38:	eb 05                	jmp    f0103d3f <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0103d3a:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103d3d:	eb 42                	jmp    f0103d81 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103d3f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103d42:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103d44:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d47:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103d4e:	eb 31                	jmp    f0103d81 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103d50:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103d53:	73 17                	jae    f0103d6c <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103d55:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103d58:	83 e8 01             	sub    $0x1,%eax
f0103d5b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103d5e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103d61:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d63:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103d6a:	eb 15                	jmp    f0103d81 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103d6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d6f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103d72:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0103d74:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103d78:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d7a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103d81:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103d84:	0f 8e 6f ff ff ff    	jle    f0103cf9 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103d8a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103d8e:	75 0f                	jne    f0103d9f <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103d90:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d93:	8b 00                	mov    (%eax),%eax
f0103d95:	83 e8 01             	sub    $0x1,%eax
f0103d98:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103d9b:	89 07                	mov    %eax,(%edi)
f0103d9d:	eb 2c                	jmp    f0103dcb <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d9f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103da2:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103da4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103da7:	8b 0f                	mov    (%edi),%ecx
f0103da9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103dac:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103daf:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103db2:	eb 03                	jmp    f0103db7 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103db4:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103db7:	39 c8                	cmp    %ecx,%eax
f0103db9:	7e 0b                	jle    f0103dc6 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103dbb:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103dbf:	83 ea 0c             	sub    $0xc,%edx
f0103dc2:	39 f3                	cmp    %esi,%ebx
f0103dc4:	75 ee                	jne    f0103db4 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103dc6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103dc9:	89 07                	mov    %eax,(%edi)
	}
}
f0103dcb:	83 c4 14             	add    $0x14,%esp
f0103dce:	5b                   	pop    %ebx
f0103dcf:	5e                   	pop    %esi
f0103dd0:	5f                   	pop    %edi
f0103dd1:	5d                   	pop    %ebp
f0103dd2:	c3                   	ret    

f0103dd3 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103dd3:	55                   	push   %ebp
f0103dd4:	89 e5                	mov    %esp,%ebp
f0103dd6:	57                   	push   %edi
f0103dd7:	56                   	push   %esi
f0103dd8:	53                   	push   %ebx
f0103dd9:	83 ec 4c             	sub    $0x4c,%esp
f0103ddc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103ddf:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103de2:	c7 07 37 64 10 f0    	movl   $0xf0106437,(%edi)
	info->eip_line = 0;
f0103de8:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0103def:	c7 47 08 37 64 10 f0 	movl   $0xf0106437,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103df6:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103dfd:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0103e00:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103e07:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103e0d:	77 21                	ja     f0103e30 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103e0f:	a1 00 00 20 00       	mov    0x200000,%eax
f0103e14:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0103e17:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103e1c:	8b 35 08 00 20 00    	mov    0x200008,%esi
f0103e22:	89 75 c0             	mov    %esi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103e25:	8b 35 0c 00 20 00    	mov    0x20000c,%esi
f0103e2b:	89 75 bc             	mov    %esi,-0x44(%ebp)
f0103e2e:	eb 1a                	jmp    f0103e4a <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103e30:	c7 45 bc 4b 10 11 f0 	movl   $0xf011104b,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103e37:	c7 45 c0 4d e2 10 f0 	movl   $0xf010e24d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103e3e:	b8 4c e2 10 f0       	mov    $0xf010e24c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103e43:	c7 45 c4 50 66 10 f0 	movl   $0xf0106650,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103e4a:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0103e4d:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f0103e50:	0f 83 9f 01 00 00    	jae    f0103ff5 <debuginfo_eip+0x222>
f0103e56:	80 7e ff 00          	cmpb   $0x0,-0x1(%esi)
f0103e5a:	0f 85 9c 01 00 00    	jne    f0103ffc <debuginfo_eip+0x229>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103e60:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103e67:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103e6a:	29 f0                	sub    %esi,%eax
f0103e6c:	c1 f8 02             	sar    $0x2,%eax
f0103e6f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103e75:	83 e8 01             	sub    $0x1,%eax
f0103e78:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103e7b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103e7f:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103e86:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103e89:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103e8c:	89 f0                	mov    %esi,%eax
f0103e8e:	e8 3e fe ff ff       	call   f0103cd1 <stab_binsearch>
	if (lfile == 0)
f0103e93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103e96:	85 c0                	test   %eax,%eax
f0103e98:	0f 84 65 01 00 00    	je     f0104003 <debuginfo_eip+0x230>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103e9e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103ea1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103ea4:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103ea7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103eab:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103eb2:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103eb5:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103eb8:	89 f0                	mov    %esi,%eax
f0103eba:	e8 12 fe ff ff       	call   f0103cd1 <stab_binsearch>

	if (lfun <= rfun) {
f0103ebf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103ec2:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0103ec5:	39 c8                	cmp    %ecx,%eax
f0103ec7:	7f 32                	jg     f0103efb <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103ec9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103ecc:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103ecf:	8d 34 96             	lea    (%esi,%edx,4),%esi
f0103ed2:	8b 16                	mov    (%esi),%edx
f0103ed4:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103ed7:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103eda:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103edd:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0103ee0:	73 09                	jae    f0103eeb <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103ee2:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103ee5:	03 55 c0             	add    -0x40(%ebp),%edx
f0103ee8:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103eeb:	8b 56 08             	mov    0x8(%esi),%edx
f0103eee:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0103ef1:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0103ef3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103ef6:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0103ef9:	eb 0f                	jmp    f0103f0a <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103efb:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0103efe:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f01:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103f04:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f07:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103f0a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103f11:	00 
f0103f12:	8b 47 08             	mov    0x8(%edi),%eax
f0103f15:	89 04 24             	mov    %eax,(%esp)
f0103f18:	e8 ee 08 00 00       	call   f010480b <strfind>
f0103f1d:	2b 47 08             	sub    0x8(%edi),%eax
f0103f20:	89 47 0c             	mov    %eax,0xc(%edi)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103f23:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f27:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103f2e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103f31:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103f34:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103f37:	e8 95 fd ff ff       	call   f0103cd1 <stab_binsearch>
	if (lline <= rline) {
f0103f3c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103f3f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103f42:	7f 0e                	jg     f0103f52 <debuginfo_eip+0x17f>
		info->eip_line = stabs[lline].n_desc;
f0103f44:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103f47:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103f4a:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0103f4f:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0103f52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f55:	89 c6                	mov    %eax,%esi
f0103f57:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103f5a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103f5d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103f60:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0103f63:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103f66:	89 f7                	mov    %esi,%edi
f0103f68:	eb 06                	jmp    f0103f70 <debuginfo_eip+0x19d>
f0103f6a:	83 e8 01             	sub    $0x1,%eax
f0103f6d:	83 ea 0c             	sub    $0xc,%edx
f0103f70:	89 c6                	mov    %eax,%esi
f0103f72:	39 c7                	cmp    %eax,%edi
f0103f74:	7f 3c                	jg     f0103fb2 <debuginfo_eip+0x1df>
f0103f76:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103f7a:	80 f9 84             	cmp    $0x84,%cl
f0103f7d:	75 08                	jne    f0103f87 <debuginfo_eip+0x1b4>
f0103f7f:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103f82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103f85:	eb 11                	jmp    f0103f98 <debuginfo_eip+0x1c5>
f0103f87:	80 f9 64             	cmp    $0x64,%cl
f0103f8a:	75 de                	jne    f0103f6a <debuginfo_eip+0x197>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103f8c:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103f90:	74 d8                	je     f0103f6a <debuginfo_eip+0x197>
f0103f92:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103f95:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103f98:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103f9b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0103f9e:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0103fa1:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103fa4:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103fa7:	39 d0                	cmp    %edx,%eax
f0103fa9:	73 0a                	jae    f0103fb5 <debuginfo_eip+0x1e2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103fab:	03 45 c0             	add    -0x40(%ebp),%eax
f0103fae:	89 07                	mov    %eax,(%edi)
f0103fb0:	eb 03                	jmp    f0103fb5 <debuginfo_eip+0x1e2>
f0103fb2:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103fb5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103fb8:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103fbb:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103fc0:	39 da                	cmp    %ebx,%edx
f0103fc2:	7d 4b                	jge    f010400f <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
f0103fc4:	83 c2 01             	add    $0x1,%edx
f0103fc7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103fca:	89 d0                	mov    %edx,%eax
f0103fcc:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103fcf:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103fd2:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103fd5:	eb 04                	jmp    f0103fdb <debuginfo_eip+0x208>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103fd7:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103fdb:	39 c3                	cmp    %eax,%ebx
f0103fdd:	7e 2b                	jle    f010400a <debuginfo_eip+0x237>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103fdf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103fe3:	83 c0 01             	add    $0x1,%eax
f0103fe6:	83 c2 0c             	add    $0xc,%edx
f0103fe9:	80 f9 a0             	cmp    $0xa0,%cl
f0103fec:	74 e9                	je     f0103fd7 <debuginfo_eip+0x204>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103fee:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ff3:	eb 1a                	jmp    f010400f <debuginfo_eip+0x23c>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103ff5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ffa:	eb 13                	jmp    f010400f <debuginfo_eip+0x23c>
f0103ffc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104001:	eb 0c                	jmp    f010400f <debuginfo_eip+0x23c>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104003:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104008:	eb 05                	jmp    f010400f <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010400a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010400f:	83 c4 4c             	add    $0x4c,%esp
f0104012:	5b                   	pop    %ebx
f0104013:	5e                   	pop    %esi
f0104014:	5f                   	pop    %edi
f0104015:	5d                   	pop    %ebp
f0104016:	c3                   	ret    
f0104017:	66 90                	xchg   %ax,%ax
f0104019:	66 90                	xchg   %ax,%ax
f010401b:	66 90                	xchg   %ax,%ax
f010401d:	66 90                	xchg   %ax,%ax
f010401f:	90                   	nop

f0104020 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104020:	55                   	push   %ebp
f0104021:	89 e5                	mov    %esp,%ebp
f0104023:	57                   	push   %edi
f0104024:	56                   	push   %esi
f0104025:	53                   	push   %ebx
f0104026:	83 ec 3c             	sub    $0x3c,%esp
f0104029:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010402c:	89 d7                	mov    %edx,%edi
f010402e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104031:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104034:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104037:	89 c3                	mov    %eax,%ebx
f0104039:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010403c:	8b 45 10             	mov    0x10(%ebp),%eax
f010403f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104042:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104047:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010404a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010404d:	39 d9                	cmp    %ebx,%ecx
f010404f:	72 05                	jb     f0104056 <printnum+0x36>
f0104051:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104054:	77 69                	ja     f01040bf <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104056:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104059:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010405d:	83 ee 01             	sub    $0x1,%esi
f0104060:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104064:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104068:	8b 44 24 08          	mov    0x8(%esp),%eax
f010406c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104070:	89 c3                	mov    %eax,%ebx
f0104072:	89 d6                	mov    %edx,%esi
f0104074:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104077:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010407a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010407e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104082:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104085:	89 04 24             	mov    %eax,(%esp)
f0104088:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010408b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010408f:	e8 9c 09 00 00       	call   f0104a30 <__udivdi3>
f0104094:	89 d9                	mov    %ebx,%ecx
f0104096:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010409a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010409e:	89 04 24             	mov    %eax,(%esp)
f01040a1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01040a5:	89 fa                	mov    %edi,%edx
f01040a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01040aa:	e8 71 ff ff ff       	call   f0104020 <printnum>
f01040af:	eb 1b                	jmp    f01040cc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01040b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01040b5:	8b 45 18             	mov    0x18(%ebp),%eax
f01040b8:	89 04 24             	mov    %eax,(%esp)
f01040bb:	ff d3                	call   *%ebx
f01040bd:	eb 03                	jmp    f01040c2 <printnum+0xa2>
f01040bf:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01040c2:	83 ee 01             	sub    $0x1,%esi
f01040c5:	85 f6                	test   %esi,%esi
f01040c7:	7f e8                	jg     f01040b1 <printnum+0x91>
f01040c9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01040cc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01040d0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01040d4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01040d7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01040da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040de:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01040e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040e5:	89 04 24             	mov    %eax,(%esp)
f01040e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01040eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040ef:	e8 6c 0a 00 00       	call   f0104b60 <__umoddi3>
f01040f4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01040f8:	0f be 80 41 64 10 f0 	movsbl -0xfef9bbf(%eax),%eax
f01040ff:	89 04 24             	mov    %eax,(%esp)
f0104102:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104105:	ff d0                	call   *%eax
}
f0104107:	83 c4 3c             	add    $0x3c,%esp
f010410a:	5b                   	pop    %ebx
f010410b:	5e                   	pop    %esi
f010410c:	5f                   	pop    %edi
f010410d:	5d                   	pop    %ebp
f010410e:	c3                   	ret    

f010410f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010410f:	55                   	push   %ebp
f0104110:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104112:	83 fa 01             	cmp    $0x1,%edx
f0104115:	7e 0e                	jle    f0104125 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104117:	8b 10                	mov    (%eax),%edx
f0104119:	8d 4a 08             	lea    0x8(%edx),%ecx
f010411c:	89 08                	mov    %ecx,(%eax)
f010411e:	8b 02                	mov    (%edx),%eax
f0104120:	8b 52 04             	mov    0x4(%edx),%edx
f0104123:	eb 22                	jmp    f0104147 <getuint+0x38>
	else if (lflag)
f0104125:	85 d2                	test   %edx,%edx
f0104127:	74 10                	je     f0104139 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104129:	8b 10                	mov    (%eax),%edx
f010412b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010412e:	89 08                	mov    %ecx,(%eax)
f0104130:	8b 02                	mov    (%edx),%eax
f0104132:	ba 00 00 00 00       	mov    $0x0,%edx
f0104137:	eb 0e                	jmp    f0104147 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104139:	8b 10                	mov    (%eax),%edx
f010413b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010413e:	89 08                	mov    %ecx,(%eax)
f0104140:	8b 02                	mov    (%edx),%eax
f0104142:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104147:	5d                   	pop    %ebp
f0104148:	c3                   	ret    

f0104149 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0104149:	55                   	push   %ebp
f010414a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010414c:	83 fa 01             	cmp    $0x1,%edx
f010414f:	7e 0e                	jle    f010415f <getint+0x16>
		return va_arg(*ap, long long);
f0104151:	8b 10                	mov    (%eax),%edx
f0104153:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104156:	89 08                	mov    %ecx,(%eax)
f0104158:	8b 02                	mov    (%edx),%eax
f010415a:	8b 52 04             	mov    0x4(%edx),%edx
f010415d:	eb 1a                	jmp    f0104179 <getint+0x30>
	else if (lflag)
f010415f:	85 d2                	test   %edx,%edx
f0104161:	74 0c                	je     f010416f <getint+0x26>
		return va_arg(*ap, long);
f0104163:	8b 10                	mov    (%eax),%edx
f0104165:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104168:	89 08                	mov    %ecx,(%eax)
f010416a:	8b 02                	mov    (%edx),%eax
f010416c:	99                   	cltd   
f010416d:	eb 0a                	jmp    f0104179 <getint+0x30>
	else
		return va_arg(*ap, int);
f010416f:	8b 10                	mov    (%eax),%edx
f0104171:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104174:	89 08                	mov    %ecx,(%eax)
f0104176:	8b 02                	mov    (%edx),%eax
f0104178:	99                   	cltd   
}
f0104179:	5d                   	pop    %ebp
f010417a:	c3                   	ret    

f010417b <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010417b:	55                   	push   %ebp
f010417c:	89 e5                	mov    %esp,%ebp
f010417e:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104181:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104185:	8b 10                	mov    (%eax),%edx
f0104187:	3b 50 04             	cmp    0x4(%eax),%edx
f010418a:	73 0a                	jae    f0104196 <sprintputch+0x1b>
		*b->buf++ = ch;
f010418c:	8d 4a 01             	lea    0x1(%edx),%ecx
f010418f:	89 08                	mov    %ecx,(%eax)
f0104191:	8b 45 08             	mov    0x8(%ebp),%eax
f0104194:	88 02                	mov    %al,(%edx)
}
f0104196:	5d                   	pop    %ebp
f0104197:	c3                   	ret    

f0104198 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104198:	55                   	push   %ebp
f0104199:	89 e5                	mov    %esp,%ebp
f010419b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010419e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01041a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01041a5:	8b 45 10             	mov    0x10(%ebp),%eax
f01041a8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01041ac:	8b 45 0c             	mov    0xc(%ebp),%eax
f01041af:	89 44 24 04          	mov    %eax,0x4(%esp)
f01041b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01041b6:	89 04 24             	mov    %eax,(%esp)
f01041b9:	e8 02 00 00 00       	call   f01041c0 <vprintfmt>
	va_end(ap);
}
f01041be:	c9                   	leave  
f01041bf:	c3                   	ret    

f01041c0 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01041c0:	55                   	push   %ebp
f01041c1:	89 e5                	mov    %esp,%ebp
f01041c3:	57                   	push   %edi
f01041c4:	56                   	push   %esi
f01041c5:	53                   	push   %ebx
f01041c6:	83 ec 3c             	sub    $0x3c,%esp
f01041c9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041cc:	8b 7d 10             	mov    0x10(%ebp),%edi
f01041cf:	eb 14                	jmp    f01041e5 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01041d1:	85 c0                	test   %eax,%eax
f01041d3:	0f 84 63 03 00 00    	je     f010453c <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
f01041d9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01041dd:	89 04 24             	mov    %eax,(%esp)
f01041e0:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01041e3:	89 df                	mov    %ebx,%edi
f01041e5:	8d 5f 01             	lea    0x1(%edi),%ebx
f01041e8:	0f b6 07             	movzbl (%edi),%eax
f01041eb:	83 f8 25             	cmp    $0x25,%eax
f01041ee:	75 e1                	jne    f01041d1 <vprintfmt+0x11>
f01041f0:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01041f4:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01041fb:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104202:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104209:	ba 00 00 00 00       	mov    $0x0,%edx
f010420e:	eb 1d                	jmp    f010422d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104210:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0104212:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104216:	eb 15                	jmp    f010422d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104218:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010421a:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010421e:	eb 0d                	jmp    f010422d <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104220:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104223:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104226:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010422d:	8d 7b 01             	lea    0x1(%ebx),%edi
f0104230:	0f b6 0b             	movzbl (%ebx),%ecx
f0104233:	0f b6 c1             	movzbl %cl,%eax
f0104236:	83 e9 23             	sub    $0x23,%ecx
f0104239:	80 f9 55             	cmp    $0x55,%cl
f010423c:	0f 87 da 02 00 00    	ja     f010451c <vprintfmt+0x35c>
f0104242:	0f b6 c9             	movzbl %cl,%ecx
f0104245:	ff 24 8d cc 64 10 f0 	jmp    *-0xfef9b34(,%ecx,4)
f010424c:	89 fb                	mov    %edi,%ebx
f010424e:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104253:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0104256:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f010425a:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f010425d:	8d 78 d0             	lea    -0x30(%eax),%edi
f0104260:	83 ff 09             	cmp    $0x9,%edi
f0104263:	77 36                	ja     f010429b <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104265:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104268:	eb e9                	jmp    f0104253 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010426a:	8b 45 14             	mov    0x14(%ebp),%eax
f010426d:	8d 48 04             	lea    0x4(%eax),%ecx
f0104270:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104273:	8b 00                	mov    (%eax),%eax
f0104275:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104278:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010427a:	eb 22                	jmp    f010429e <vprintfmt+0xde>
f010427c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010427f:	85 c9                	test   %ecx,%ecx
f0104281:	b8 00 00 00 00       	mov    $0x0,%eax
f0104286:	0f 49 c1             	cmovns %ecx,%eax
f0104289:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010428c:	89 fb                	mov    %edi,%ebx
f010428e:	eb 9d                	jmp    f010422d <vprintfmt+0x6d>
f0104290:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104292:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104299:	eb 92                	jmp    f010422d <vprintfmt+0x6d>
f010429b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010429e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01042a2:	79 89                	jns    f010422d <vprintfmt+0x6d>
f01042a4:	e9 77 ff ff ff       	jmp    f0104220 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01042a9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042ac:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01042ae:	e9 7a ff ff ff       	jmp    f010422d <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01042b3:	8b 45 14             	mov    0x14(%ebp),%eax
f01042b6:	8d 50 04             	lea    0x4(%eax),%edx
f01042b9:	89 55 14             	mov    %edx,0x14(%ebp)
f01042bc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042c0:	8b 00                	mov    (%eax),%eax
f01042c2:	89 04 24             	mov    %eax,(%esp)
f01042c5:	ff 55 08             	call   *0x8(%ebp)
			break;
f01042c8:	e9 18 ff ff ff       	jmp    f01041e5 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01042cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01042d0:	8d 50 04             	lea    0x4(%eax),%edx
f01042d3:	89 55 14             	mov    %edx,0x14(%ebp)
f01042d6:	8b 00                	mov    (%eax),%eax
f01042d8:	99                   	cltd   
f01042d9:	31 d0                	xor    %edx,%eax
f01042db:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01042dd:	83 f8 06             	cmp    $0x6,%eax
f01042e0:	7f 0b                	jg     f01042ed <vprintfmt+0x12d>
f01042e2:	8b 14 85 24 66 10 f0 	mov    -0xfef99dc(,%eax,4),%edx
f01042e9:	85 d2                	test   %edx,%edx
f01042eb:	75 20                	jne    f010430d <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01042ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01042f1:	c7 44 24 08 59 64 10 	movl   $0xf0106459,0x8(%esp)
f01042f8:	f0 
f01042f9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01042fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104300:	89 04 24             	mov    %eax,(%esp)
f0104303:	e8 90 fe ff ff       	call   f0104198 <printfmt>
f0104308:	e9 d8 fe ff ff       	jmp    f01041e5 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010430d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104311:	c7 44 24 08 2c 5a 10 	movl   $0xf0105a2c,0x8(%esp)
f0104318:	f0 
f0104319:	89 74 24 04          	mov    %esi,0x4(%esp)
f010431d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104320:	89 04 24             	mov    %eax,(%esp)
f0104323:	e8 70 fe ff ff       	call   f0104198 <printfmt>
f0104328:	e9 b8 fe ff ff       	jmp    f01041e5 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010432d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104330:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104333:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104336:	8b 45 14             	mov    0x14(%ebp),%eax
f0104339:	8d 50 04             	lea    0x4(%eax),%edx
f010433c:	89 55 14             	mov    %edx,0x14(%ebp)
f010433f:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f0104341:	85 db                	test   %ebx,%ebx
f0104343:	b8 52 64 10 f0       	mov    $0xf0106452,%eax
f0104348:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f010434b:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010434f:	0f 84 97 00 00 00    	je     f01043ec <vprintfmt+0x22c>
f0104355:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0104359:	0f 8e 9b 00 00 00    	jle    f01043fa <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010435f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104363:	89 1c 24             	mov    %ebx,(%esp)
f0104366:	e8 4d 03 00 00       	call   f01046b8 <strnlen>
f010436b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010436e:	29 c2                	sub    %eax,%edx
f0104370:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0104373:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0104377:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010437a:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f010437d:	89 d3                	mov    %edx,%ebx
f010437f:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104382:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104385:	eb 0f                	jmp    f0104396 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104387:	89 74 24 04          	mov    %esi,0x4(%esp)
f010438b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010438e:	89 04 24             	mov    %eax,(%esp)
f0104391:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104393:	83 eb 01             	sub    $0x1,%ebx
f0104396:	85 db                	test   %ebx,%ebx
f0104398:	7f ed                	jg     f0104387 <vprintfmt+0x1c7>
f010439a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010439d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01043a0:	85 d2                	test   %edx,%edx
f01043a2:	b8 00 00 00 00       	mov    $0x0,%eax
f01043a7:	0f 49 c2             	cmovns %edx,%eax
f01043aa:	29 c2                	sub    %eax,%edx
f01043ac:	89 75 0c             	mov    %esi,0xc(%ebp)
f01043af:	89 d6                	mov    %edx,%esi
f01043b1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01043b4:	eb 50                	jmp    f0104406 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01043b6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01043ba:	74 1e                	je     f01043da <vprintfmt+0x21a>
f01043bc:	0f be d2             	movsbl %dl,%edx
f01043bf:	83 ea 20             	sub    $0x20,%edx
f01043c2:	83 fa 5e             	cmp    $0x5e,%edx
f01043c5:	76 13                	jbe    f01043da <vprintfmt+0x21a>
					putch('?', putdat);
f01043c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ce:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01043d5:	ff 55 08             	call   *0x8(%ebp)
f01043d8:	eb 0d                	jmp    f01043e7 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01043da:	8b 55 0c             	mov    0xc(%ebp),%edx
f01043dd:	89 54 24 04          	mov    %edx,0x4(%esp)
f01043e1:	89 04 24             	mov    %eax,(%esp)
f01043e4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01043e7:	83 ee 01             	sub    $0x1,%esi
f01043ea:	eb 1a                	jmp    f0104406 <vprintfmt+0x246>
f01043ec:	89 75 0c             	mov    %esi,0xc(%ebp)
f01043ef:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01043f2:	89 7d 10             	mov    %edi,0x10(%ebp)
f01043f5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01043f8:	eb 0c                	jmp    f0104406 <vprintfmt+0x246>
f01043fa:	89 75 0c             	mov    %esi,0xc(%ebp)
f01043fd:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104400:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104403:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104406:	83 c3 01             	add    $0x1,%ebx
f0104409:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f010440d:	0f be c2             	movsbl %dl,%eax
f0104410:	85 c0                	test   %eax,%eax
f0104412:	74 25                	je     f0104439 <vprintfmt+0x279>
f0104414:	85 ff                	test   %edi,%edi
f0104416:	78 9e                	js     f01043b6 <vprintfmt+0x1f6>
f0104418:	83 ef 01             	sub    $0x1,%edi
f010441b:	79 99                	jns    f01043b6 <vprintfmt+0x1f6>
f010441d:	89 f3                	mov    %esi,%ebx
f010441f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104422:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104425:	eb 1a                	jmp    f0104441 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104427:	89 74 24 04          	mov    %esi,0x4(%esp)
f010442b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104432:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104434:	83 eb 01             	sub    $0x1,%ebx
f0104437:	eb 08                	jmp    f0104441 <vprintfmt+0x281>
f0104439:	89 f3                	mov    %esi,%ebx
f010443b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010443e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104441:	85 db                	test   %ebx,%ebx
f0104443:	7f e2                	jg     f0104427 <vprintfmt+0x267>
f0104445:	89 7d 08             	mov    %edi,0x8(%ebp)
f0104448:	8b 7d 10             	mov    0x10(%ebp),%edi
f010444b:	e9 95 fd ff ff       	jmp    f01041e5 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104450:	8d 45 14             	lea    0x14(%ebp),%eax
f0104453:	e8 f1 fc ff ff       	call   f0104149 <getint>
f0104458:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010445b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010445e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104463:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104467:	79 7b                	jns    f01044e4 <vprintfmt+0x324>
				putch('-', putdat);
f0104469:	89 74 24 04          	mov    %esi,0x4(%esp)
f010446d:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0104474:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104477:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010447a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010447d:	f7 d8                	neg    %eax
f010447f:	83 d2 00             	adc    $0x0,%edx
f0104482:	f7 da                	neg    %edx
f0104484:	eb 5e                	jmp    f01044e4 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104486:	8d 45 14             	lea    0x14(%ebp),%eax
f0104489:	e8 81 fc ff ff       	call   f010410f <getuint>
			base = 10;
f010448e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
f0104493:	eb 4f                	jmp    f01044e4 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104495:	8d 45 14             	lea    0x14(%ebp),%eax
f0104498:	e8 72 fc ff ff       	call   f010410f <getuint>
			base = 8;
f010449d:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
f01044a2:	eb 40                	jmp    f01044e4 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
f01044a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01044a8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01044af:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01044b2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01044b6:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01044bd:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01044c0:	8b 45 14             	mov    0x14(%ebp),%eax
f01044c3:	8d 50 04             	lea    0x4(%eax),%edx
f01044c6:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01044c9:	8b 00                	mov    (%eax),%eax
f01044cb:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01044d0:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
f01044d5:	eb 0d                	jmp    f01044e4 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01044d7:	8d 45 14             	lea    0x14(%ebp),%eax
f01044da:	e8 30 fc ff ff       	call   f010410f <getuint>
			base = 16;
f01044df:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01044e4:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
f01044e8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01044ec:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01044ef:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01044f3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01044f7:	89 04 24             	mov    %eax,(%esp)
f01044fa:	89 54 24 04          	mov    %edx,0x4(%esp)
f01044fe:	89 f2                	mov    %esi,%edx
f0104500:	8b 45 08             	mov    0x8(%ebp),%eax
f0104503:	e8 18 fb ff ff       	call   f0104020 <printnum>
			break;
f0104508:	e9 d8 fc ff ff       	jmp    f01041e5 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010450d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104511:	89 04 24             	mov    %eax,(%esp)
f0104514:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104517:	e9 c9 fc ff ff       	jmp    f01041e5 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010451c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104520:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104527:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010452a:	89 df                	mov    %ebx,%edi
f010452c:	eb 03                	jmp    f0104531 <vprintfmt+0x371>
f010452e:	83 ef 01             	sub    $0x1,%edi
f0104531:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104535:	75 f7                	jne    f010452e <vprintfmt+0x36e>
f0104537:	e9 a9 fc ff ff       	jmp    f01041e5 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010453c:	83 c4 3c             	add    $0x3c,%esp
f010453f:	5b                   	pop    %ebx
f0104540:	5e                   	pop    %esi
f0104541:	5f                   	pop    %edi
f0104542:	5d                   	pop    %ebp
f0104543:	c3                   	ret    

f0104544 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104544:	55                   	push   %ebp
f0104545:	89 e5                	mov    %esp,%ebp
f0104547:	83 ec 28             	sub    $0x28,%esp
f010454a:	8b 45 08             	mov    0x8(%ebp),%eax
f010454d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104550:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104553:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104557:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010455a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104561:	85 c0                	test   %eax,%eax
f0104563:	74 30                	je     f0104595 <vsnprintf+0x51>
f0104565:	85 d2                	test   %edx,%edx
f0104567:	7e 2c                	jle    f0104595 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104569:	8b 45 14             	mov    0x14(%ebp),%eax
f010456c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104570:	8b 45 10             	mov    0x10(%ebp),%eax
f0104573:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104577:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010457a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010457e:	c7 04 24 7b 41 10 f0 	movl   $0xf010417b,(%esp)
f0104585:	e8 36 fc ff ff       	call   f01041c0 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010458a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010458d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104590:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104593:	eb 05                	jmp    f010459a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104595:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010459a:	c9                   	leave  
f010459b:	c3                   	ret    

f010459c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010459c:	55                   	push   %ebp
f010459d:	89 e5                	mov    %esp,%ebp
f010459f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01045a2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01045a5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01045a9:	8b 45 10             	mov    0x10(%ebp),%eax
f01045ac:	89 44 24 08          	mov    %eax,0x8(%esp)
f01045b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01045b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01045ba:	89 04 24             	mov    %eax,(%esp)
f01045bd:	e8 82 ff ff ff       	call   f0104544 <vsnprintf>
	va_end(ap);

	return rc;
}
f01045c2:	c9                   	leave  
f01045c3:	c3                   	ret    
f01045c4:	66 90                	xchg   %ax,%ax
f01045c6:	66 90                	xchg   %ax,%ax
f01045c8:	66 90                	xchg   %ax,%ax
f01045ca:	66 90                	xchg   %ax,%ax
f01045cc:	66 90                	xchg   %ax,%ax
f01045ce:	66 90                	xchg   %ax,%ax

f01045d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01045d0:	55                   	push   %ebp
f01045d1:	89 e5                	mov    %esp,%ebp
f01045d3:	57                   	push   %edi
f01045d4:	56                   	push   %esi
f01045d5:	53                   	push   %ebx
f01045d6:	83 ec 1c             	sub    $0x1c,%esp
f01045d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01045dc:	85 c0                	test   %eax,%eax
f01045de:	74 10                	je     f01045f0 <readline+0x20>
		cprintf("%s", prompt);
f01045e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045e4:	c7 04 24 2c 5a 10 f0 	movl   $0xf0105a2c,(%esp)
f01045eb:	e8 72 f2 ff ff       	call   f0103862 <cprintf>

	i = 0;
	echoing = iscons(0);
f01045f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01045f7:	e8 6d c1 ff ff       	call   f0100769 <iscons>
f01045fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01045fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104603:	e8 50 c1 ff ff       	call   f0100758 <getchar>
f0104608:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010460a:	85 c0                	test   %eax,%eax
f010460c:	79 17                	jns    f0104625 <readline+0x55>
			cprintf("read error: %e\n", c);
f010460e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104612:	c7 04 24 40 66 10 f0 	movl   $0xf0106640,(%esp)
f0104619:	e8 44 f2 ff ff       	call   f0103862 <cprintf>
			return NULL;
f010461e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104623:	eb 6d                	jmp    f0104692 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104625:	83 f8 7f             	cmp    $0x7f,%eax
f0104628:	74 05                	je     f010462f <readline+0x5f>
f010462a:	83 f8 08             	cmp    $0x8,%eax
f010462d:	75 19                	jne    f0104648 <readline+0x78>
f010462f:	85 f6                	test   %esi,%esi
f0104631:	7e 15                	jle    f0104648 <readline+0x78>
			if (echoing)
f0104633:	85 ff                	test   %edi,%edi
f0104635:	74 0c                	je     f0104643 <readline+0x73>
				cputchar('\b');
f0104637:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010463e:	e8 05 c1 ff ff       	call   f0100748 <cputchar>
			i--;
f0104643:	83 ee 01             	sub    $0x1,%esi
f0104646:	eb bb                	jmp    f0104603 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104648:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010464e:	7f 1c                	jg     f010466c <readline+0x9c>
f0104650:	83 fb 1f             	cmp    $0x1f,%ebx
f0104653:	7e 17                	jle    f010466c <readline+0x9c>
			if (echoing)
f0104655:	85 ff                	test   %edi,%edi
f0104657:	74 08                	je     f0104661 <readline+0x91>
				cputchar(c);
f0104659:	89 1c 24             	mov    %ebx,(%esp)
f010465c:	e8 e7 c0 ff ff       	call   f0100748 <cputchar>
			buf[i++] = c;
f0104661:	88 9e 80 5b 18 f0    	mov    %bl,-0xfe7a480(%esi)
f0104667:	8d 76 01             	lea    0x1(%esi),%esi
f010466a:	eb 97                	jmp    f0104603 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010466c:	83 fb 0d             	cmp    $0xd,%ebx
f010466f:	74 05                	je     f0104676 <readline+0xa6>
f0104671:	83 fb 0a             	cmp    $0xa,%ebx
f0104674:	75 8d                	jne    f0104603 <readline+0x33>
			if (echoing)
f0104676:	85 ff                	test   %edi,%edi
f0104678:	74 0c                	je     f0104686 <readline+0xb6>
				cputchar('\n');
f010467a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104681:	e8 c2 c0 ff ff       	call   f0100748 <cputchar>
			buf[i] = 0;
f0104686:	c6 86 80 5b 18 f0 00 	movb   $0x0,-0xfe7a480(%esi)
			return buf;
f010468d:	b8 80 5b 18 f0       	mov    $0xf0185b80,%eax
		}
	}
}
f0104692:	83 c4 1c             	add    $0x1c,%esp
f0104695:	5b                   	pop    %ebx
f0104696:	5e                   	pop    %esi
f0104697:	5f                   	pop    %edi
f0104698:	5d                   	pop    %ebp
f0104699:	c3                   	ret    
f010469a:	66 90                	xchg   %ax,%ax
f010469c:	66 90                	xchg   %ax,%ax
f010469e:	66 90                	xchg   %ax,%ax

f01046a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01046a0:	55                   	push   %ebp
f01046a1:	89 e5                	mov    %esp,%ebp
f01046a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01046a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01046ab:	eb 03                	jmp    f01046b0 <strlen+0x10>
		n++;
f01046ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01046b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01046b4:	75 f7                	jne    f01046ad <strlen+0xd>
		n++;
	return n;
}
f01046b6:	5d                   	pop    %ebp
f01046b7:	c3                   	ret    

f01046b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01046b8:	55                   	push   %ebp
f01046b9:	89 e5                	mov    %esp,%ebp
f01046bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01046be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01046c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01046c6:	eb 03                	jmp    f01046cb <strnlen+0x13>
		n++;
f01046c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01046cb:	39 d0                	cmp    %edx,%eax
f01046cd:	74 06                	je     f01046d5 <strnlen+0x1d>
f01046cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01046d3:	75 f3                	jne    f01046c8 <strnlen+0x10>
		n++;
	return n;
}
f01046d5:	5d                   	pop    %ebp
f01046d6:	c3                   	ret    

f01046d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01046d7:	55                   	push   %ebp
f01046d8:	89 e5                	mov    %esp,%ebp
f01046da:	53                   	push   %ebx
f01046db:	8b 45 08             	mov    0x8(%ebp),%eax
f01046de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01046e1:	89 c2                	mov    %eax,%edx
f01046e3:	83 c2 01             	add    $0x1,%edx
f01046e6:	83 c1 01             	add    $0x1,%ecx
f01046e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01046ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01046f0:	84 db                	test   %bl,%bl
f01046f2:	75 ef                	jne    f01046e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01046f4:	5b                   	pop    %ebx
f01046f5:	5d                   	pop    %ebp
f01046f6:	c3                   	ret    

f01046f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01046f7:	55                   	push   %ebp
f01046f8:	89 e5                	mov    %esp,%ebp
f01046fa:	53                   	push   %ebx
f01046fb:	83 ec 08             	sub    $0x8,%esp
f01046fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104701:	89 1c 24             	mov    %ebx,(%esp)
f0104704:	e8 97 ff ff ff       	call   f01046a0 <strlen>
	strcpy(dst + len, src);
f0104709:	8b 55 0c             	mov    0xc(%ebp),%edx
f010470c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104710:	01 d8                	add    %ebx,%eax
f0104712:	89 04 24             	mov    %eax,(%esp)
f0104715:	e8 bd ff ff ff       	call   f01046d7 <strcpy>
	return dst;
}
f010471a:	89 d8                	mov    %ebx,%eax
f010471c:	83 c4 08             	add    $0x8,%esp
f010471f:	5b                   	pop    %ebx
f0104720:	5d                   	pop    %ebp
f0104721:	c3                   	ret    

f0104722 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104722:	55                   	push   %ebp
f0104723:	89 e5                	mov    %esp,%ebp
f0104725:	56                   	push   %esi
f0104726:	53                   	push   %ebx
f0104727:	8b 75 08             	mov    0x8(%ebp),%esi
f010472a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010472d:	89 f3                	mov    %esi,%ebx
f010472f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104732:	89 f2                	mov    %esi,%edx
f0104734:	eb 0f                	jmp    f0104745 <strncpy+0x23>
		*dst++ = *src;
f0104736:	83 c2 01             	add    $0x1,%edx
f0104739:	0f b6 01             	movzbl (%ecx),%eax
f010473c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010473f:	80 39 01             	cmpb   $0x1,(%ecx)
f0104742:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104745:	39 da                	cmp    %ebx,%edx
f0104747:	75 ed                	jne    f0104736 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104749:	89 f0                	mov    %esi,%eax
f010474b:	5b                   	pop    %ebx
f010474c:	5e                   	pop    %esi
f010474d:	5d                   	pop    %ebp
f010474e:	c3                   	ret    

f010474f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010474f:	55                   	push   %ebp
f0104750:	89 e5                	mov    %esp,%ebp
f0104752:	56                   	push   %esi
f0104753:	53                   	push   %ebx
f0104754:	8b 75 08             	mov    0x8(%ebp),%esi
f0104757:	8b 55 0c             	mov    0xc(%ebp),%edx
f010475a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010475d:	89 f0                	mov    %esi,%eax
f010475f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104763:	85 c9                	test   %ecx,%ecx
f0104765:	75 0b                	jne    f0104772 <strlcpy+0x23>
f0104767:	eb 1d                	jmp    f0104786 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104769:	83 c0 01             	add    $0x1,%eax
f010476c:	83 c2 01             	add    $0x1,%edx
f010476f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104772:	39 d8                	cmp    %ebx,%eax
f0104774:	74 0b                	je     f0104781 <strlcpy+0x32>
f0104776:	0f b6 0a             	movzbl (%edx),%ecx
f0104779:	84 c9                	test   %cl,%cl
f010477b:	75 ec                	jne    f0104769 <strlcpy+0x1a>
f010477d:	89 c2                	mov    %eax,%edx
f010477f:	eb 02                	jmp    f0104783 <strlcpy+0x34>
f0104781:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104783:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104786:	29 f0                	sub    %esi,%eax
}
f0104788:	5b                   	pop    %ebx
f0104789:	5e                   	pop    %esi
f010478a:	5d                   	pop    %ebp
f010478b:	c3                   	ret    

f010478c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010478c:	55                   	push   %ebp
f010478d:	89 e5                	mov    %esp,%ebp
f010478f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104792:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104795:	eb 06                	jmp    f010479d <strcmp+0x11>
		p++, q++;
f0104797:	83 c1 01             	add    $0x1,%ecx
f010479a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010479d:	0f b6 01             	movzbl (%ecx),%eax
f01047a0:	84 c0                	test   %al,%al
f01047a2:	74 04                	je     f01047a8 <strcmp+0x1c>
f01047a4:	3a 02                	cmp    (%edx),%al
f01047a6:	74 ef                	je     f0104797 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01047a8:	0f b6 c0             	movzbl %al,%eax
f01047ab:	0f b6 12             	movzbl (%edx),%edx
f01047ae:	29 d0                	sub    %edx,%eax
}
f01047b0:	5d                   	pop    %ebp
f01047b1:	c3                   	ret    

f01047b2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01047b2:	55                   	push   %ebp
f01047b3:	89 e5                	mov    %esp,%ebp
f01047b5:	53                   	push   %ebx
f01047b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01047b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047bc:	89 c3                	mov    %eax,%ebx
f01047be:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01047c1:	eb 06                	jmp    f01047c9 <strncmp+0x17>
		n--, p++, q++;
f01047c3:	83 c0 01             	add    $0x1,%eax
f01047c6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01047c9:	39 d8                	cmp    %ebx,%eax
f01047cb:	74 15                	je     f01047e2 <strncmp+0x30>
f01047cd:	0f b6 08             	movzbl (%eax),%ecx
f01047d0:	84 c9                	test   %cl,%cl
f01047d2:	74 04                	je     f01047d8 <strncmp+0x26>
f01047d4:	3a 0a                	cmp    (%edx),%cl
f01047d6:	74 eb                	je     f01047c3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01047d8:	0f b6 00             	movzbl (%eax),%eax
f01047db:	0f b6 12             	movzbl (%edx),%edx
f01047de:	29 d0                	sub    %edx,%eax
f01047e0:	eb 05                	jmp    f01047e7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01047e2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01047e7:	5b                   	pop    %ebx
f01047e8:	5d                   	pop    %ebp
f01047e9:	c3                   	ret    

f01047ea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01047ea:	55                   	push   %ebp
f01047eb:	89 e5                	mov    %esp,%ebp
f01047ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01047f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01047f4:	eb 07                	jmp    f01047fd <strchr+0x13>
		if (*s == c)
f01047f6:	38 ca                	cmp    %cl,%dl
f01047f8:	74 0f                	je     f0104809 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01047fa:	83 c0 01             	add    $0x1,%eax
f01047fd:	0f b6 10             	movzbl (%eax),%edx
f0104800:	84 d2                	test   %dl,%dl
f0104802:	75 f2                	jne    f01047f6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104804:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104809:	5d                   	pop    %ebp
f010480a:	c3                   	ret    

f010480b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010480b:	55                   	push   %ebp
f010480c:	89 e5                	mov    %esp,%ebp
f010480e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104811:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104815:	eb 07                	jmp    f010481e <strfind+0x13>
		if (*s == c)
f0104817:	38 ca                	cmp    %cl,%dl
f0104819:	74 0a                	je     f0104825 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010481b:	83 c0 01             	add    $0x1,%eax
f010481e:	0f b6 10             	movzbl (%eax),%edx
f0104821:	84 d2                	test   %dl,%dl
f0104823:	75 f2                	jne    f0104817 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104825:	5d                   	pop    %ebp
f0104826:	c3                   	ret    

f0104827 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104827:	55                   	push   %ebp
f0104828:	89 e5                	mov    %esp,%ebp
f010482a:	57                   	push   %edi
f010482b:	56                   	push   %esi
f010482c:	53                   	push   %ebx
f010482d:	8b 55 08             	mov    0x8(%ebp),%edx
f0104830:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0104833:	85 c9                	test   %ecx,%ecx
f0104835:	74 37                	je     f010486e <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104837:	f6 c2 03             	test   $0x3,%dl
f010483a:	75 2a                	jne    f0104866 <memset+0x3f>
f010483c:	f6 c1 03             	test   $0x3,%cl
f010483f:	75 25                	jne    f0104866 <memset+0x3f>
		c &= 0xFF;
f0104841:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104845:	89 fb                	mov    %edi,%ebx
f0104847:	c1 e3 08             	shl    $0x8,%ebx
f010484a:	89 fe                	mov    %edi,%esi
f010484c:	c1 e6 18             	shl    $0x18,%esi
f010484f:	89 f8                	mov    %edi,%eax
f0104851:	c1 e0 10             	shl    $0x10,%eax
f0104854:	09 f0                	or     %esi,%eax
f0104856:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0104858:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010485b:	89 f8                	mov    %edi,%eax
f010485d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f010485f:	89 d7                	mov    %edx,%edi
f0104861:	fc                   	cld    
f0104862:	f3 ab                	rep stos %eax,%es:(%edi)
f0104864:	eb 08                	jmp    f010486e <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104866:	89 d7                	mov    %edx,%edi
f0104868:	8b 45 0c             	mov    0xc(%ebp),%eax
f010486b:	fc                   	cld    
f010486c:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f010486e:	89 d0                	mov    %edx,%eax
f0104870:	5b                   	pop    %ebx
f0104871:	5e                   	pop    %esi
f0104872:	5f                   	pop    %edi
f0104873:	5d                   	pop    %ebp
f0104874:	c3                   	ret    

f0104875 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104875:	55                   	push   %ebp
f0104876:	89 e5                	mov    %esp,%ebp
f0104878:	57                   	push   %edi
f0104879:	56                   	push   %esi
f010487a:	8b 45 08             	mov    0x8(%ebp),%eax
f010487d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104880:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104883:	39 c6                	cmp    %eax,%esi
f0104885:	73 35                	jae    f01048bc <memmove+0x47>
f0104887:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010488a:	39 d0                	cmp    %edx,%eax
f010488c:	73 2e                	jae    f01048bc <memmove+0x47>
		s += n;
		d += n;
f010488e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104891:	89 d6                	mov    %edx,%esi
f0104893:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104895:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010489b:	75 13                	jne    f01048b0 <memmove+0x3b>
f010489d:	f6 c1 03             	test   $0x3,%cl
f01048a0:	75 0e                	jne    f01048b0 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01048a2:	83 ef 04             	sub    $0x4,%edi
f01048a5:	8d 72 fc             	lea    -0x4(%edx),%esi
f01048a8:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01048ab:	fd                   	std    
f01048ac:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01048ae:	eb 09                	jmp    f01048b9 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01048b0:	83 ef 01             	sub    $0x1,%edi
f01048b3:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01048b6:	fd                   	std    
f01048b7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01048b9:	fc                   	cld    
f01048ba:	eb 1d                	jmp    f01048d9 <memmove+0x64>
f01048bc:	89 f2                	mov    %esi,%edx
f01048be:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01048c0:	f6 c2 03             	test   $0x3,%dl
f01048c3:	75 0f                	jne    f01048d4 <memmove+0x5f>
f01048c5:	f6 c1 03             	test   $0x3,%cl
f01048c8:	75 0a                	jne    f01048d4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01048ca:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01048cd:	89 c7                	mov    %eax,%edi
f01048cf:	fc                   	cld    
f01048d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01048d2:	eb 05                	jmp    f01048d9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01048d4:	89 c7                	mov    %eax,%edi
f01048d6:	fc                   	cld    
f01048d7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01048d9:	5e                   	pop    %esi
f01048da:	5f                   	pop    %edi
f01048db:	5d                   	pop    %ebp
f01048dc:	c3                   	ret    

f01048dd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01048dd:	55                   	push   %ebp
f01048de:	89 e5                	mov    %esp,%ebp
f01048e0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01048e3:	8b 45 10             	mov    0x10(%ebp),%eax
f01048e6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01048ea:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01048f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01048f4:	89 04 24             	mov    %eax,(%esp)
f01048f7:	e8 79 ff ff ff       	call   f0104875 <memmove>
}
f01048fc:	c9                   	leave  
f01048fd:	c3                   	ret    

f01048fe <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01048fe:	55                   	push   %ebp
f01048ff:	89 e5                	mov    %esp,%ebp
f0104901:	56                   	push   %esi
f0104902:	53                   	push   %ebx
f0104903:	8b 55 08             	mov    0x8(%ebp),%edx
f0104906:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104909:	89 d6                	mov    %edx,%esi
f010490b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010490e:	eb 1a                	jmp    f010492a <memcmp+0x2c>
		if (*s1 != *s2)
f0104910:	0f b6 02             	movzbl (%edx),%eax
f0104913:	0f b6 19             	movzbl (%ecx),%ebx
f0104916:	38 d8                	cmp    %bl,%al
f0104918:	74 0a                	je     f0104924 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010491a:	0f b6 c0             	movzbl %al,%eax
f010491d:	0f b6 db             	movzbl %bl,%ebx
f0104920:	29 d8                	sub    %ebx,%eax
f0104922:	eb 0f                	jmp    f0104933 <memcmp+0x35>
		s1++, s2++;
f0104924:	83 c2 01             	add    $0x1,%edx
f0104927:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010492a:	39 f2                	cmp    %esi,%edx
f010492c:	75 e2                	jne    f0104910 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010492e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104933:	5b                   	pop    %ebx
f0104934:	5e                   	pop    %esi
f0104935:	5d                   	pop    %ebp
f0104936:	c3                   	ret    

f0104937 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104937:	55                   	push   %ebp
f0104938:	89 e5                	mov    %esp,%ebp
f010493a:	8b 45 08             	mov    0x8(%ebp),%eax
f010493d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104940:	89 c2                	mov    %eax,%edx
f0104942:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104945:	eb 07                	jmp    f010494e <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104947:	38 08                	cmp    %cl,(%eax)
f0104949:	74 07                	je     f0104952 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010494b:	83 c0 01             	add    $0x1,%eax
f010494e:	39 d0                	cmp    %edx,%eax
f0104950:	72 f5                	jb     f0104947 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104952:	5d                   	pop    %ebp
f0104953:	c3                   	ret    

f0104954 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104954:	55                   	push   %ebp
f0104955:	89 e5                	mov    %esp,%ebp
f0104957:	57                   	push   %edi
f0104958:	56                   	push   %esi
f0104959:	53                   	push   %ebx
f010495a:	8b 55 08             	mov    0x8(%ebp),%edx
f010495d:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104960:	eb 03                	jmp    f0104965 <strtol+0x11>
		s++;
f0104962:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104965:	0f b6 0a             	movzbl (%edx),%ecx
f0104968:	80 f9 09             	cmp    $0x9,%cl
f010496b:	74 f5                	je     f0104962 <strtol+0xe>
f010496d:	80 f9 20             	cmp    $0x20,%cl
f0104970:	74 f0                	je     f0104962 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104972:	80 f9 2b             	cmp    $0x2b,%cl
f0104975:	75 0a                	jne    f0104981 <strtol+0x2d>
		s++;
f0104977:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010497a:	bf 00 00 00 00       	mov    $0x0,%edi
f010497f:	eb 11                	jmp    f0104992 <strtol+0x3e>
f0104981:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104986:	80 f9 2d             	cmp    $0x2d,%cl
f0104989:	75 07                	jne    f0104992 <strtol+0x3e>
		s++, neg = 1;
f010498b:	8d 52 01             	lea    0x1(%edx),%edx
f010498e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104992:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104997:	75 15                	jne    f01049ae <strtol+0x5a>
f0104999:	80 3a 30             	cmpb   $0x30,(%edx)
f010499c:	75 10                	jne    f01049ae <strtol+0x5a>
f010499e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01049a2:	75 0a                	jne    f01049ae <strtol+0x5a>
		s += 2, base = 16;
f01049a4:	83 c2 02             	add    $0x2,%edx
f01049a7:	b8 10 00 00 00       	mov    $0x10,%eax
f01049ac:	eb 10                	jmp    f01049be <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01049ae:	85 c0                	test   %eax,%eax
f01049b0:	75 0c                	jne    f01049be <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01049b2:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01049b4:	80 3a 30             	cmpb   $0x30,(%edx)
f01049b7:	75 05                	jne    f01049be <strtol+0x6a>
		s++, base = 8;
f01049b9:	83 c2 01             	add    $0x1,%edx
f01049bc:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01049be:	bb 00 00 00 00       	mov    $0x0,%ebx
f01049c3:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01049c6:	0f b6 0a             	movzbl (%edx),%ecx
f01049c9:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01049cc:	89 f0                	mov    %esi,%eax
f01049ce:	3c 09                	cmp    $0x9,%al
f01049d0:	77 08                	ja     f01049da <strtol+0x86>
			dig = *s - '0';
f01049d2:	0f be c9             	movsbl %cl,%ecx
f01049d5:	83 e9 30             	sub    $0x30,%ecx
f01049d8:	eb 20                	jmp    f01049fa <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f01049da:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01049dd:	89 f0                	mov    %esi,%eax
f01049df:	3c 19                	cmp    $0x19,%al
f01049e1:	77 08                	ja     f01049eb <strtol+0x97>
			dig = *s - 'a' + 10;
f01049e3:	0f be c9             	movsbl %cl,%ecx
f01049e6:	83 e9 57             	sub    $0x57,%ecx
f01049e9:	eb 0f                	jmp    f01049fa <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f01049eb:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01049ee:	89 f0                	mov    %esi,%eax
f01049f0:	3c 19                	cmp    $0x19,%al
f01049f2:	77 16                	ja     f0104a0a <strtol+0xb6>
			dig = *s - 'A' + 10;
f01049f4:	0f be c9             	movsbl %cl,%ecx
f01049f7:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01049fa:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01049fd:	7d 0f                	jge    f0104a0e <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01049ff:	83 c2 01             	add    $0x1,%edx
f0104a02:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104a06:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104a08:	eb bc                	jmp    f01049c6 <strtol+0x72>
f0104a0a:	89 d8                	mov    %ebx,%eax
f0104a0c:	eb 02                	jmp    f0104a10 <strtol+0xbc>
f0104a0e:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104a10:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104a14:	74 05                	je     f0104a1b <strtol+0xc7>
		*endptr = (char *) s;
f0104a16:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104a19:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104a1b:	f7 d8                	neg    %eax
f0104a1d:	85 ff                	test   %edi,%edi
f0104a1f:	0f 44 c3             	cmove  %ebx,%eax
}
f0104a22:	5b                   	pop    %ebx
f0104a23:	5e                   	pop    %esi
f0104a24:	5f                   	pop    %edi
f0104a25:	5d                   	pop    %ebp
f0104a26:	c3                   	ret    
f0104a27:	66 90                	xchg   %ax,%ax
f0104a29:	66 90                	xchg   %ax,%ax
f0104a2b:	66 90                	xchg   %ax,%ax
f0104a2d:	66 90                	xchg   %ax,%ax
f0104a2f:	90                   	nop

f0104a30 <__udivdi3>:
f0104a30:	55                   	push   %ebp
f0104a31:	57                   	push   %edi
f0104a32:	56                   	push   %esi
f0104a33:	83 ec 0c             	sub    $0xc,%esp
f0104a36:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104a3a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104a3e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104a42:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104a46:	85 c0                	test   %eax,%eax
f0104a48:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104a4c:	89 ea                	mov    %ebp,%edx
f0104a4e:	89 0c 24             	mov    %ecx,(%esp)
f0104a51:	75 2d                	jne    f0104a80 <__udivdi3+0x50>
f0104a53:	39 e9                	cmp    %ebp,%ecx
f0104a55:	77 61                	ja     f0104ab8 <__udivdi3+0x88>
f0104a57:	85 c9                	test   %ecx,%ecx
f0104a59:	89 ce                	mov    %ecx,%esi
f0104a5b:	75 0b                	jne    f0104a68 <__udivdi3+0x38>
f0104a5d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104a62:	31 d2                	xor    %edx,%edx
f0104a64:	f7 f1                	div    %ecx
f0104a66:	89 c6                	mov    %eax,%esi
f0104a68:	31 d2                	xor    %edx,%edx
f0104a6a:	89 e8                	mov    %ebp,%eax
f0104a6c:	f7 f6                	div    %esi
f0104a6e:	89 c5                	mov    %eax,%ebp
f0104a70:	89 f8                	mov    %edi,%eax
f0104a72:	f7 f6                	div    %esi
f0104a74:	89 ea                	mov    %ebp,%edx
f0104a76:	83 c4 0c             	add    $0xc,%esp
f0104a79:	5e                   	pop    %esi
f0104a7a:	5f                   	pop    %edi
f0104a7b:	5d                   	pop    %ebp
f0104a7c:	c3                   	ret    
f0104a7d:	8d 76 00             	lea    0x0(%esi),%esi
f0104a80:	39 e8                	cmp    %ebp,%eax
f0104a82:	77 24                	ja     f0104aa8 <__udivdi3+0x78>
f0104a84:	0f bd e8             	bsr    %eax,%ebp
f0104a87:	83 f5 1f             	xor    $0x1f,%ebp
f0104a8a:	75 3c                	jne    f0104ac8 <__udivdi3+0x98>
f0104a8c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104a90:	39 34 24             	cmp    %esi,(%esp)
f0104a93:	0f 86 9f 00 00 00    	jbe    f0104b38 <__udivdi3+0x108>
f0104a99:	39 d0                	cmp    %edx,%eax
f0104a9b:	0f 82 97 00 00 00    	jb     f0104b38 <__udivdi3+0x108>
f0104aa1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104aa8:	31 d2                	xor    %edx,%edx
f0104aaa:	31 c0                	xor    %eax,%eax
f0104aac:	83 c4 0c             	add    $0xc,%esp
f0104aaf:	5e                   	pop    %esi
f0104ab0:	5f                   	pop    %edi
f0104ab1:	5d                   	pop    %ebp
f0104ab2:	c3                   	ret    
f0104ab3:	90                   	nop
f0104ab4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ab8:	89 f8                	mov    %edi,%eax
f0104aba:	f7 f1                	div    %ecx
f0104abc:	31 d2                	xor    %edx,%edx
f0104abe:	83 c4 0c             	add    $0xc,%esp
f0104ac1:	5e                   	pop    %esi
f0104ac2:	5f                   	pop    %edi
f0104ac3:	5d                   	pop    %ebp
f0104ac4:	c3                   	ret    
f0104ac5:	8d 76 00             	lea    0x0(%esi),%esi
f0104ac8:	89 e9                	mov    %ebp,%ecx
f0104aca:	8b 3c 24             	mov    (%esp),%edi
f0104acd:	d3 e0                	shl    %cl,%eax
f0104acf:	89 c6                	mov    %eax,%esi
f0104ad1:	b8 20 00 00 00       	mov    $0x20,%eax
f0104ad6:	29 e8                	sub    %ebp,%eax
f0104ad8:	89 c1                	mov    %eax,%ecx
f0104ada:	d3 ef                	shr    %cl,%edi
f0104adc:	89 e9                	mov    %ebp,%ecx
f0104ade:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104ae2:	8b 3c 24             	mov    (%esp),%edi
f0104ae5:	09 74 24 08          	or     %esi,0x8(%esp)
f0104ae9:	89 d6                	mov    %edx,%esi
f0104aeb:	d3 e7                	shl    %cl,%edi
f0104aed:	89 c1                	mov    %eax,%ecx
f0104aef:	89 3c 24             	mov    %edi,(%esp)
f0104af2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104af6:	d3 ee                	shr    %cl,%esi
f0104af8:	89 e9                	mov    %ebp,%ecx
f0104afa:	d3 e2                	shl    %cl,%edx
f0104afc:	89 c1                	mov    %eax,%ecx
f0104afe:	d3 ef                	shr    %cl,%edi
f0104b00:	09 d7                	or     %edx,%edi
f0104b02:	89 f2                	mov    %esi,%edx
f0104b04:	89 f8                	mov    %edi,%eax
f0104b06:	f7 74 24 08          	divl   0x8(%esp)
f0104b0a:	89 d6                	mov    %edx,%esi
f0104b0c:	89 c7                	mov    %eax,%edi
f0104b0e:	f7 24 24             	mull   (%esp)
f0104b11:	39 d6                	cmp    %edx,%esi
f0104b13:	89 14 24             	mov    %edx,(%esp)
f0104b16:	72 30                	jb     f0104b48 <__udivdi3+0x118>
f0104b18:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104b1c:	89 e9                	mov    %ebp,%ecx
f0104b1e:	d3 e2                	shl    %cl,%edx
f0104b20:	39 c2                	cmp    %eax,%edx
f0104b22:	73 05                	jae    f0104b29 <__udivdi3+0xf9>
f0104b24:	3b 34 24             	cmp    (%esp),%esi
f0104b27:	74 1f                	je     f0104b48 <__udivdi3+0x118>
f0104b29:	89 f8                	mov    %edi,%eax
f0104b2b:	31 d2                	xor    %edx,%edx
f0104b2d:	e9 7a ff ff ff       	jmp    f0104aac <__udivdi3+0x7c>
f0104b32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104b38:	31 d2                	xor    %edx,%edx
f0104b3a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b3f:	e9 68 ff ff ff       	jmp    f0104aac <__udivdi3+0x7c>
f0104b44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104b48:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104b4b:	31 d2                	xor    %edx,%edx
f0104b4d:	83 c4 0c             	add    $0xc,%esp
f0104b50:	5e                   	pop    %esi
f0104b51:	5f                   	pop    %edi
f0104b52:	5d                   	pop    %ebp
f0104b53:	c3                   	ret    
f0104b54:	66 90                	xchg   %ax,%ax
f0104b56:	66 90                	xchg   %ax,%ax
f0104b58:	66 90                	xchg   %ax,%ax
f0104b5a:	66 90                	xchg   %ax,%ax
f0104b5c:	66 90                	xchg   %ax,%ax
f0104b5e:	66 90                	xchg   %ax,%ax

f0104b60 <__umoddi3>:
f0104b60:	55                   	push   %ebp
f0104b61:	57                   	push   %edi
f0104b62:	56                   	push   %esi
f0104b63:	83 ec 14             	sub    $0x14,%esp
f0104b66:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104b6a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104b6e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104b72:	89 c7                	mov    %eax,%edi
f0104b74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b78:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104b7c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104b80:	89 34 24             	mov    %esi,(%esp)
f0104b83:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104b87:	85 c0                	test   %eax,%eax
f0104b89:	89 c2                	mov    %eax,%edx
f0104b8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104b8f:	75 17                	jne    f0104ba8 <__umoddi3+0x48>
f0104b91:	39 fe                	cmp    %edi,%esi
f0104b93:	76 4b                	jbe    f0104be0 <__umoddi3+0x80>
f0104b95:	89 c8                	mov    %ecx,%eax
f0104b97:	89 fa                	mov    %edi,%edx
f0104b99:	f7 f6                	div    %esi
f0104b9b:	89 d0                	mov    %edx,%eax
f0104b9d:	31 d2                	xor    %edx,%edx
f0104b9f:	83 c4 14             	add    $0x14,%esp
f0104ba2:	5e                   	pop    %esi
f0104ba3:	5f                   	pop    %edi
f0104ba4:	5d                   	pop    %ebp
f0104ba5:	c3                   	ret    
f0104ba6:	66 90                	xchg   %ax,%ax
f0104ba8:	39 f8                	cmp    %edi,%eax
f0104baa:	77 54                	ja     f0104c00 <__umoddi3+0xa0>
f0104bac:	0f bd e8             	bsr    %eax,%ebp
f0104baf:	83 f5 1f             	xor    $0x1f,%ebp
f0104bb2:	75 5c                	jne    f0104c10 <__umoddi3+0xb0>
f0104bb4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104bb8:	39 3c 24             	cmp    %edi,(%esp)
f0104bbb:	0f 87 e7 00 00 00    	ja     f0104ca8 <__umoddi3+0x148>
f0104bc1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104bc5:	29 f1                	sub    %esi,%ecx
f0104bc7:	19 c7                	sbb    %eax,%edi
f0104bc9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104bcd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104bd1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104bd5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104bd9:	83 c4 14             	add    $0x14,%esp
f0104bdc:	5e                   	pop    %esi
f0104bdd:	5f                   	pop    %edi
f0104bde:	5d                   	pop    %ebp
f0104bdf:	c3                   	ret    
f0104be0:	85 f6                	test   %esi,%esi
f0104be2:	89 f5                	mov    %esi,%ebp
f0104be4:	75 0b                	jne    f0104bf1 <__umoddi3+0x91>
f0104be6:	b8 01 00 00 00       	mov    $0x1,%eax
f0104beb:	31 d2                	xor    %edx,%edx
f0104bed:	f7 f6                	div    %esi
f0104bef:	89 c5                	mov    %eax,%ebp
f0104bf1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104bf5:	31 d2                	xor    %edx,%edx
f0104bf7:	f7 f5                	div    %ebp
f0104bf9:	89 c8                	mov    %ecx,%eax
f0104bfb:	f7 f5                	div    %ebp
f0104bfd:	eb 9c                	jmp    f0104b9b <__umoddi3+0x3b>
f0104bff:	90                   	nop
f0104c00:	89 c8                	mov    %ecx,%eax
f0104c02:	89 fa                	mov    %edi,%edx
f0104c04:	83 c4 14             	add    $0x14,%esp
f0104c07:	5e                   	pop    %esi
f0104c08:	5f                   	pop    %edi
f0104c09:	5d                   	pop    %ebp
f0104c0a:	c3                   	ret    
f0104c0b:	90                   	nop
f0104c0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104c10:	8b 04 24             	mov    (%esp),%eax
f0104c13:	be 20 00 00 00       	mov    $0x20,%esi
f0104c18:	89 e9                	mov    %ebp,%ecx
f0104c1a:	29 ee                	sub    %ebp,%esi
f0104c1c:	d3 e2                	shl    %cl,%edx
f0104c1e:	89 f1                	mov    %esi,%ecx
f0104c20:	d3 e8                	shr    %cl,%eax
f0104c22:	89 e9                	mov    %ebp,%ecx
f0104c24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c28:	8b 04 24             	mov    (%esp),%eax
f0104c2b:	09 54 24 04          	or     %edx,0x4(%esp)
f0104c2f:	89 fa                	mov    %edi,%edx
f0104c31:	d3 e0                	shl    %cl,%eax
f0104c33:	89 f1                	mov    %esi,%ecx
f0104c35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c39:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104c3d:	d3 ea                	shr    %cl,%edx
f0104c3f:	89 e9                	mov    %ebp,%ecx
f0104c41:	d3 e7                	shl    %cl,%edi
f0104c43:	89 f1                	mov    %esi,%ecx
f0104c45:	d3 e8                	shr    %cl,%eax
f0104c47:	89 e9                	mov    %ebp,%ecx
f0104c49:	09 f8                	or     %edi,%eax
f0104c4b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0104c4f:	f7 74 24 04          	divl   0x4(%esp)
f0104c53:	d3 e7                	shl    %cl,%edi
f0104c55:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104c59:	89 d7                	mov    %edx,%edi
f0104c5b:	f7 64 24 08          	mull   0x8(%esp)
f0104c5f:	39 d7                	cmp    %edx,%edi
f0104c61:	89 c1                	mov    %eax,%ecx
f0104c63:	89 14 24             	mov    %edx,(%esp)
f0104c66:	72 2c                	jb     f0104c94 <__umoddi3+0x134>
f0104c68:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0104c6c:	72 22                	jb     f0104c90 <__umoddi3+0x130>
f0104c6e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104c72:	29 c8                	sub    %ecx,%eax
f0104c74:	19 d7                	sbb    %edx,%edi
f0104c76:	89 e9                	mov    %ebp,%ecx
f0104c78:	89 fa                	mov    %edi,%edx
f0104c7a:	d3 e8                	shr    %cl,%eax
f0104c7c:	89 f1                	mov    %esi,%ecx
f0104c7e:	d3 e2                	shl    %cl,%edx
f0104c80:	89 e9                	mov    %ebp,%ecx
f0104c82:	d3 ef                	shr    %cl,%edi
f0104c84:	09 d0                	or     %edx,%eax
f0104c86:	89 fa                	mov    %edi,%edx
f0104c88:	83 c4 14             	add    $0x14,%esp
f0104c8b:	5e                   	pop    %esi
f0104c8c:	5f                   	pop    %edi
f0104c8d:	5d                   	pop    %ebp
f0104c8e:	c3                   	ret    
f0104c8f:	90                   	nop
f0104c90:	39 d7                	cmp    %edx,%edi
f0104c92:	75 da                	jne    f0104c6e <__umoddi3+0x10e>
f0104c94:	8b 14 24             	mov    (%esp),%edx
f0104c97:	89 c1                	mov    %eax,%ecx
f0104c99:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0104c9d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0104ca1:	eb cb                	jmp    f0104c6e <__umoddi3+0x10e>
f0104ca3:	90                   	nop
f0104ca4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104ca8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0104cac:	0f 82 0f ff ff ff    	jb     f0104bc1 <__umoddi3+0x61>
f0104cb2:	e9 1a ff ff ff       	jmp    f0104bd1 <__umoddi3+0x71>
