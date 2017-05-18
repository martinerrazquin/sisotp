
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 10 00       	mov    $0x10f000,%eax
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
f010003d:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

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
f0100056:	b8 f0 3e 1a f0       	mov    $0xf01a3ef0,%eax
f010005b:	2d e0 1f 1a f0       	sub    $0xf01a1fe0,%eax
f0100060:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100064:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010006b:	00 
f010006c:	c7 04 24 e0 1f 1a f0 	movl   $0xf01a1fe0,(%esp)
f0100073:	e8 1f 4b 00 00       	call   f0104b97 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100078:	e8 a4 06 00 00       	call   f0100721 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010007d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100084:	00 
f0100085:	c7 04 24 40 50 10 f0 	movl   $0xf0105040,(%esp)
f010008c:	e8 61 36 00 00       	call   f01036f2 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100091:	e8 71 2b 00 00       	call   f0102c07 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100096:	e8 fc 31 00 00       	call   f0103297 <env_init>
f010009b:	90                   	nop
f010009c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
	trap_init();
f01000a0:	e8 0a 37 00 00       	call   f01037af <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01000a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000ac:	00 
f01000ad:	c7 04 24 76 1e 13 f0 	movl   $0xf0131e76,(%esp)
f01000b4:	e8 16 33 00 00       	call   f01033cf <env_create>
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b9:	a1 28 22 1a f0       	mov    0xf01a2228,%eax
f01000be:	89 04 24             	mov    %eax,(%esp)
f01000c1:	e8 e9 34 00 00       	call   f01035af <env_run>

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
f01000d1:	83 3d e0 3e 1a f0 00 	cmpl   $0x0,0xf01a3ee0
f01000d8:	75 3d                	jne    f0100117 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000da:	89 35 e0 3e 1a f0    	mov    %esi,0xf01a3ee0

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
f01000f3:	c7 04 24 7c 50 10 f0 	movl   $0xf010507c,(%esp)
f01000fa:	e8 f3 35 00 00       	call   f01036f2 <cprintf>
	vcprintf(fmt, ap);
f01000ff:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100103:	89 34 24             	mov    %esi,(%esp)
f0100106:	e8 b4 35 00 00       	call   f01036bf <vcprintf>
	cprintf("\n>>>\n");
f010010b:	c7 04 24 5b 50 10 f0 	movl   $0xf010505b,(%esp)
f0100112:	e8 db 35 00 00       	call   f01036f2 <cprintf>
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
f010013d:	c7 04 24 61 50 10 f0 	movl   $0xf0105061,(%esp)
f0100144:	e8 a9 35 00 00       	call   f01036f2 <cprintf>
	vcprintf(fmt, ap);
f0100149:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010014d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100150:	89 04 24             	mov    %eax,(%esp)
f0100153:	e8 67 35 00 00       	call   f01036bf <vcprintf>
	cprintf("\n");
f0100158:	c7 04 24 0a 62 10 f0 	movl   $0xf010620a,(%esp)
f010015f:	e8 8e 35 00 00       	call   f01036f2 <cprintf>
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
f0100289:	0f 95 05 14 22 1a f0 	setne  0xf01a2214
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
f0100323:	c7 05 10 22 1a f0 b4 	movl   $0x3b4,0xf01a2210
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
f010033b:	c7 05 10 22 1a f0 d4 	movl   $0x3d4,0xf01a2210
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
f010034a:	8b 1d 10 22 1a f0    	mov    0xf01a2210,%ebx
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
f0100382:	89 3d 0c 22 1a f0    	mov    %edi,0xf01a220c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100388:	0f b6 c0             	movzbl %al,%eax
f010038b:	0b 45 f0             	or     -0x10(%ebp),%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010038e:	66 a3 08 22 1a f0    	mov    %ax,0xf01a2208
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
f01003ab:	a1 04 22 1a f0       	mov    0xf01a2204,%eax
f01003b0:	8d 48 01             	lea    0x1(%eax),%ecx
f01003b3:	89 0d 04 22 1a f0    	mov    %ecx,0xf01a2204
f01003b9:	88 90 00 20 1a f0    	mov    %dl,-0xfe5e000(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01003bf:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01003c5:	75 0a                	jne    f01003d1 <cons_intr+0x35>
			cons.wpos = 0;
f01003c7:	c7 05 04 22 1a f0 00 	movl   $0x0,0xf01a2204
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
f010040f:	83 0d e0 1f 1a f0 40 	orl    $0x40,0xf01a1fe0
		return 0;
f0100416:	b8 00 00 00 00       	mov    $0x0,%eax
f010041b:	e9 e2 00 00 00       	jmp    f0100502 <kbd_proc_data+0x122>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 39                	jns    f010045d <kbd_proc_data+0x7d>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 15 e0 1f 1a f0    	mov    0xf01a1fe0,%edx
f010042a:	89 d3                	mov    %edx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	89 c1                	mov    %eax,%ecx
f0100431:	83 e1 7f             	and    $0x7f,%ecx
f0100434:	85 db                	test   %ebx,%ebx
f0100436:	0f 44 c1             	cmove  %ecx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100439:	0f b6 c0             	movzbl %al,%eax
f010043c:	0f b6 80 00 52 10 f0 	movzbl -0xfefae00(%eax),%eax
f0100443:	83 c8 40             	or     $0x40,%eax
f0100446:	0f b6 c0             	movzbl %al,%eax
f0100449:	f7 d0                	not    %eax
f010044b:	21 c2                	and    %eax,%edx
f010044d:	89 15 e0 1f 1a f0    	mov    %edx,0xf01a1fe0
		return 0;
f0100453:	b8 00 00 00 00       	mov    $0x0,%eax
f0100458:	e9 a5 00 00 00       	jmp    f0100502 <kbd_proc_data+0x122>
	} else if (shift & E0ESC) {
f010045d:	8b 15 e0 1f 1a f0    	mov    0xf01a1fe0,%edx
f0100463:	f6 c2 40             	test   $0x40,%dl
f0100466:	74 0c                	je     f0100474 <kbd_proc_data+0x94>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100468:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f010046b:	83 e2 bf             	and    $0xffffffbf,%edx
f010046e:	89 15 e0 1f 1a f0    	mov    %edx,0xf01a1fe0
	}

	shift |= shiftcode[data];
f0100474:	0f b6 c0             	movzbl %al,%eax
f0100477:	0f b6 90 00 52 10 f0 	movzbl -0xfefae00(%eax),%edx
f010047e:	0b 15 e0 1f 1a f0    	or     0xf01a1fe0,%edx
	shift ^= togglecode[data];
f0100484:	0f b6 88 00 51 10 f0 	movzbl -0xfefaf00(%eax),%ecx
f010048b:	31 ca                	xor    %ecx,%edx
f010048d:	89 15 e0 1f 1a f0    	mov    %edx,0xf01a1fe0

	c = charcode[shift & (CTL | SHIFT)][data];
f0100493:	89 d1                	mov    %edx,%ecx
f0100495:	83 e1 03             	and    $0x3,%ecx
f0100498:	8b 0c 8d e0 50 10 f0 	mov    -0xfefaf20(,%ecx,4),%ecx
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
f01004d7:	c7 04 24 9c 50 10 f0 	movl   $0xf010509c,(%esp)
f01004de:	e8 0f 32 00 00       	call   f01036f2 <cprintf>
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
f010054c:	0f b7 15 08 22 1a f0 	movzwl 0xf01a2208,%edx
f0100553:	66 85 d2             	test   %dx,%dx
f0100556:	0f 84 e3 00 00 00    	je     f010063f <cga_putc+0x137>
			crt_pos--;
f010055c:	83 ea 01             	sub    $0x1,%edx
f010055f:	66 89 15 08 22 1a f0 	mov    %dx,0xf01a2208
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100566:	0f b7 d2             	movzwl %dx,%edx
f0100569:	b0 00                	mov    $0x0,%al
f010056b:	83 c8 20             	or     $0x20,%eax
f010056e:	8b 0d 0c 22 1a f0    	mov    0xf01a220c,%ecx
f0100574:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100578:	eb 78                	jmp    f01005f2 <cga_putc+0xea>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010057a:	66 83 05 08 22 1a f0 	addw   $0x50,0xf01a2208
f0100581:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100582:	0f b7 05 08 22 1a f0 	movzwl 0xf01a2208,%eax
f0100589:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010058f:	c1 e8 16             	shr    $0x16,%eax
f0100592:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100595:	c1 e0 04             	shl    $0x4,%eax
f0100598:	66 a3 08 22 1a f0    	mov    %ax,0xf01a2208
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
f01005d4:	0f b7 15 08 22 1a f0 	movzwl 0xf01a2208,%edx
f01005db:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005de:	66 89 0d 08 22 1a f0 	mov    %cx,0xf01a2208
f01005e5:	0f b7 d2             	movzwl %dx,%edx
f01005e8:	8b 0d 0c 22 1a f0    	mov    0xf01a220c,%ecx
f01005ee:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005f2:	66 81 3d 08 22 1a f0 	cmpw   $0x7cf,0xf01a2208
f01005f9:	cf 07 
f01005fb:	76 42                	jbe    f010063f <cga_putc+0x137>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005fd:	a1 0c 22 1a f0       	mov    0xf01a220c,%eax
f0100602:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100609:	00 
f010060a:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100610:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100614:	89 04 24             	mov    %eax,(%esp)
f0100617:	e8 c9 45 00 00       	call   f0104be5 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010061c:	8b 15 0c 22 1a f0    	mov    0xf01a220c,%edx
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
f0100637:	66 83 2d 08 22 1a f0 	subw   $0x50,0xf01a2208
f010063e:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010063f:	8b 1d 10 22 1a f0    	mov    0xf01a2210,%ebx
f0100645:	ba 0e 00 00 00       	mov    $0xe,%edx
f010064a:	89 d8                	mov    %ebx,%eax
f010064c:	e8 27 fb ff ff       	call   f0100178 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f0100651:	0f b7 3d 08 22 1a f0 	movzwl 0xf01a2208,%edi
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
f01006a9:	80 3d 14 22 1a f0 00 	cmpb   $0x0,0xf01a2214
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
f01006e7:	a1 00 22 1a f0       	mov    0xf01a2200,%eax
f01006ec:	3b 05 04 22 1a f0    	cmp    0xf01a2204,%eax
f01006f2:	74 26                	je     f010071a <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006f4:	8d 50 01             	lea    0x1(%eax),%edx
f01006f7:	89 15 00 22 1a f0    	mov    %edx,0xf01a2200
f01006fd:	0f b6 88 00 20 1a f0 	movzbl -0xfe5e000(%eax),%ecx
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
f010070e:	c7 05 00 22 1a f0 00 	movl   $0x0,0xf01a2200
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
f0100731:	80 3d 14 22 1a f0 00 	cmpb   $0x0,0xf01a2214
f0100738:	75 0c                	jne    f0100746 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f010073a:	c7 04 24 a8 50 10 f0 	movl   $0xf01050a8,(%esp)
f0100741:	e8 ac 2f 00 00       	call   f01036f2 <cprintf>
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
f0100786:	c7 44 24 08 00 53 10 	movl   $0xf0105300,0x8(%esp)
f010078d:	f0 
f010078e:	c7 44 24 04 1e 53 10 	movl   $0xf010531e,0x4(%esp)
f0100795:	f0 
f0100796:	c7 04 24 23 53 10 f0 	movl   $0xf0105323,(%esp)
f010079d:	e8 50 2f 00 00       	call   f01036f2 <cprintf>
f01007a2:	c7 44 24 08 c0 53 10 	movl   $0xf01053c0,0x8(%esp)
f01007a9:	f0 
f01007aa:	c7 44 24 04 2c 53 10 	movl   $0xf010532c,0x4(%esp)
f01007b1:	f0 
f01007b2:	c7 04 24 23 53 10 f0 	movl   $0xf0105323,(%esp)
f01007b9:	e8 34 2f 00 00       	call   f01036f2 <cprintf>
f01007be:	c7 44 24 08 35 53 10 	movl   $0xf0105335,0x8(%esp)
f01007c5:	f0 
f01007c6:	c7 44 24 04 49 53 10 	movl   $0xf0105349,0x4(%esp)
f01007cd:	f0 
f01007ce:	c7 04 24 23 53 10 f0 	movl   $0xf0105323,(%esp)
f01007d5:	e8 18 2f 00 00       	call   f01036f2 <cprintf>
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
f01007e7:	c7 04 24 53 53 10 f0 	movl   $0xf0105353,(%esp)
f01007ee:	e8 ff 2e 00 00       	call   f01036f2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01007fa:	00 
f01007fb:	c7 04 24 e8 53 10 f0 	movl   $0xf01053e8,(%esp)
f0100802:	e8 eb 2e 00 00       	call   f01036f2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100807:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010080e:	00 
f010080f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100816:	f0 
f0100817:	c7 04 24 10 54 10 f0 	movl   $0xf0105410,(%esp)
f010081e:	e8 cf 2e 00 00       	call   f01036f2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100823:	c7 44 24 08 27 50 10 	movl   $0x105027,0x8(%esp)
f010082a:	00 
f010082b:	c7 44 24 04 27 50 10 	movl   $0xf0105027,0x4(%esp)
f0100832:	f0 
f0100833:	c7 04 24 34 54 10 f0 	movl   $0xf0105434,(%esp)
f010083a:	e8 b3 2e 00 00       	call   f01036f2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010083f:	c7 44 24 08 cc 1f 1a 	movl   $0x1a1fcc,0x8(%esp)
f0100846:	00 
f0100847:	c7 44 24 04 cc 1f 1a 	movl   $0xf01a1fcc,0x4(%esp)
f010084e:	f0 
f010084f:	c7 04 24 58 54 10 f0 	movl   $0xf0105458,(%esp)
f0100856:	e8 97 2e 00 00       	call   f01036f2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010085b:	c7 44 24 08 f0 3e 1a 	movl   $0x1a3ef0,0x8(%esp)
f0100862:	00 
f0100863:	c7 44 24 04 f0 3e 1a 	movl   $0xf01a3ef0,0x4(%esp)
f010086a:	f0 
f010086b:	c7 04 24 7c 54 10 f0 	movl   $0xf010547c,(%esp)
f0100872:	e8 7b 2e 00 00       	call   f01036f2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100877:	b8 ef 42 1a f0       	mov    $0xf01a42ef,%eax
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
f0100898:	c7 04 24 a0 54 10 f0 	movl   $0xf01054a0,(%esp)
f010089f:	e8 4e 2e 00 00       	call   f01036f2 <cprintf>
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
f01008e9:	c7 04 24 cc 54 10 f0 	movl   $0xf01054cc,(%esp)
f01008f0:	e8 fd 2d 00 00       	call   f01036f2 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f01008f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008f9:	89 34 24             	mov    %esi,(%esp)
f01008fc:	e8 44 38 00 00       	call   f0104145 <debuginfo_eip>
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
f0100924:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f010092b:	e8 c2 2d 00 00       	call   f01036f2 <cprintf>
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
f0100977:	c7 04 24 83 53 10 f0 	movl   $0xf0105383,(%esp)
f010097e:	e8 d7 41 00 00       	call   f0104b5a <strchr>
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
f010099a:	c7 04 24 88 53 10 f0 	movl   $0xf0105388,(%esp)
f01009a1:	e8 4c 2d 00 00       	call   f01036f2 <cprintf>
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
f01009ca:	c7 04 24 83 53 10 f0 	movl   $0xf0105383,(%esp)
f01009d1:	e8 84 41 00 00       	call   f0104b5a <strchr>
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
f01009f5:	8b 04 85 60 55 10 f0 	mov    -0xfefaaa0(,%eax,4),%eax
f01009fc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a00:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a03:	89 04 24             	mov    %eax,(%esp)
f0100a06:	e8 f1 40 00 00       	call   f0104afc <strcmp>
f0100a0b:	85 c0                	test   %eax,%eax
f0100a0d:	75 1d                	jne    f0100a2c <runcmd+0xe9>
			return commands[i].func(argc, argv, tf);
f0100a0f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a12:	8b 4d a4             	mov    -0x5c(%ebp),%ecx
f0100a15:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100a19:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a1c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a20:	89 34 24             	mov    %esi,(%esp)
f0100a23:	ff 14 85 68 55 10 f0 	call   *-0xfefaa98(,%eax,4)
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
f0100a3b:	c7 04 24 a5 53 10 f0 	movl   $0xf01053a5,(%esp)
f0100a42:	e8 ab 2c 00 00       	call   f01036f2 <cprintf>
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
f0100a5e:	c7 04 24 00 55 10 f0 	movl   $0xf0105500,(%esp)
f0100a65:	e8 88 2c 00 00       	call   f01036f2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100a6a:	c7 04 24 24 55 10 f0 	movl   $0xf0105524,(%esp)
f0100a71:	e8 7c 2c 00 00       	call   f01036f2 <cprintf>

	if (tf != NULL)
f0100a76:	85 db                	test   %ebx,%ebx
f0100a78:	74 08                	je     f0100a82 <monitor+0x2e>
		print_trapframe(tf);
f0100a7a:	89 1c 24             	mov    %ebx,(%esp)
f0100a7d:	e8 2a 31 00 00       	call   f0103bac <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100a82:	c7 04 24 bb 53 10 f0 	movl   $0xf01053bb,(%esp)
f0100a89:	e8 b2 3e 00 00       	call   f0104940 <readline>
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
f0100ac6:	2b 05 ec 3e 1a f0    	sub    0xf01a3eec,%eax
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
f0100ae1:	e8 85 2b 00 00       	call   f010366b <mc146818_read>
f0100ae6:	89 c6                	mov    %eax,%esi
f0100ae8:	83 c3 01             	add    $0x1,%ebx
f0100aeb:	89 1c 24             	mov    %ebx,(%esp)
f0100aee:	e8 78 2b 00 00       	call   f010366b <mc146818_read>
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
f0100b47:	89 15 e4 3e 1a f0    	mov    %edx,0xf01a3ee4
	npages_basemem = basemem / (PGSIZE / 1024);
f0100b4d:	89 da                	mov    %ebx,%edx
f0100b4f:	c1 ea 02             	shr    $0x2,%edx
f0100b52:	89 15 20 22 1a f0    	mov    %edx,0xf01a2220

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b58:	89 c2                	mov    %eax,%edx
f0100b5a:	29 da                	sub    %ebx,%edx
f0100b5c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100b60:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100b64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b68:	c7 04 24 84 55 10 f0 	movl   $0xf0105584,(%esp)
f0100b6f:	e8 7e 2b 00 00       	call   f01036f2 <cprintf>
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
f0100b87:	3b 1d e4 3e 1a f0    	cmp    0xf01a3ee4,%ebx
f0100b8d:	72 18                	jb     f0100ba7 <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b8f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100b93:	c7 44 24 08 c0 55 10 	movl   $0xf01055c0,0x8(%esp)
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
f0100bc5:	b8 6d 5d 10 f0       	mov    $0xf0105d6d,%eax
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
f0100c0b:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
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
f0100c4f:	c7 44 24 08 e4 55 10 	movl   $0xf01055e4,0x8(%esp)
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
f0100c6a:	83 3d 18 22 1a f0 00 	cmpl   $0x0,0xf01a2218
f0100c71:	75 11                	jne    f0100c84 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100c73:	ba ef 4e 1a f0       	mov    $0xf01a4eef,%edx
f0100c78:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c7e:	89 15 18 22 1a f0    	mov    %edx,0xf01a2218
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100c84:	85 c0                	test   %eax,%eax
f0100c86:	75 06                	jne    f0100c8e <boot_alloc+0x24>
f0100c88:	a1 18 22 1a f0       	mov    0xf01a2218,%eax
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
f0100c95:	8b 1d 18 22 1a f0    	mov    0xf01a2218,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100c9b:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100ca1:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100ca7:	01 d9                	add    %ebx,%ecx
f0100ca9:	89 0d 18 22 1a f0    	mov    %ecx,0xf01a2218
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100caf:	ba 6e 00 00 00       	mov    $0x6e,%edx
f0100cb4:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0100cb9:	e8 7f ff ff ff       	call   f0100c3d <_paddr>
f0100cbe:	8b 15 e4 3e 1a f0    	mov    0xf01a3ee4,%edx
f0100cc4:	c1 e2 0c             	shl    $0xc,%edx
f0100cc7:	39 d0                	cmp    %edx,%eax
f0100cc9:	76 1c                	jbe    f0100ce7 <boot_alloc+0x7d>
f0100ccb:	c7 44 24 08 87 5d 10 	movl   $0xf0105d87,0x8(%esp)
f0100cd2:	f0 
f0100cd3:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100cda:	00 
f0100cdb:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100cf8:	8b 1d e8 3e 1a f0    	mov    0xf01a3ee8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100cfe:	a1 e4 3e 1a f0       	mov    0xf01a3ee4,%eax
f0100d03:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100d06:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100d0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100d12:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100d15:	a1 ec 3e 1a f0       	mov    0xf01a3eec,%eax
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
f0100d3b:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0100d40:	e8 f8 fe ff ff       	call   f0100c3d <_paddr>
f0100d45:	01 f0                	add    %esi,%eax
f0100d47:	39 c7                	cmp    %eax,%edi
f0100d49:	74 24                	je     f0100d6f <check_kern_pgdir+0x80>
f0100d4b:	c7 44 24 0c 08 56 10 	movl   $0xf0105608,0xc(%esp)
f0100d52:	f0 
f0100d53:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100d5a:	f0 
f0100d5b:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0100d62:	00 
f0100d63:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100d7a:	a1 28 22 1a f0       	mov    0xf01a2228,%eax
f0100d7f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100d82:	be 00 00 00 00       	mov    $0x0,%esi
f0100d87:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
f0100d8d:	89 d8                	mov    %ebx,%eax
f0100d8f:	e8 3d fe ff ff       	call   f0100bd1 <check_va2pa>
f0100d94:	89 c7                	mov    %eax,%edi
f0100d96:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d99:	ba e2 02 00 00       	mov    $0x2e2,%edx
f0100d9e:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0100da3:	e8 95 fe ff ff       	call   f0100c3d <_paddr>
f0100da8:	01 f0                	add    %esi,%eax
f0100daa:	39 c7                	cmp    %eax,%edi
f0100dac:	74 24                	je     f0100dd2 <check_kern_pgdir+0xe3>
f0100dae:	c7 44 24 0c 3c 56 10 	movl   $0xf010563c,0xc(%esp)
f0100db5:	f0 
f0100db6:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100dbd:	f0 
f0100dbe:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f0100dc5:	00 
f0100dc6:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100dfe:	c7 44 24 0c 70 56 10 	movl   $0xf0105670,0xc(%esp)
f0100e05:	f0 
f0100e06:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100e0d:	f0 
f0100e0e:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
f0100e15:	00 
f0100e16:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100e40:	b9 00 70 10 f0       	mov    $0xf0107000,%ecx
f0100e45:	ba ea 02 00 00       	mov    $0x2ea,%edx
f0100e4a:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0100e4f:	e8 e9 fd ff ff       	call   f0100c3d <_paddr>
f0100e54:	01 f0                	add    %esi,%eax
f0100e56:	39 c7                	cmp    %eax,%edi
f0100e58:	74 24                	je     f0100e7e <check_kern_pgdir+0x18f>
f0100e5a:	c7 44 24 0c 98 56 10 	movl   $0xf0105698,0xc(%esp)
f0100e61:	f0 
f0100e62:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100e69:	f0 
f0100e6a:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0100e71:	00 
f0100e72:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100ea7:	c7 44 24 0c e0 56 10 	movl   $0xf01056e0,0xc(%esp)
f0100eae:	f0 
f0100eaf:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100eb6:	f0 
f0100eb7:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0100ebe:	00 
f0100ebf:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100eea:	c7 44 24 0c af 5d 10 	movl   $0xf0105daf,0xc(%esp)
f0100ef1:	f0 
f0100ef2:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100ef9:	f0 
f0100efa:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f0100f01:	00 
f0100f02:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100f1d:	c7 44 24 0c af 5d 10 	movl   $0xf0105daf,0xc(%esp)
f0100f24:	f0 
f0100f25:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100f2c:	f0 
f0100f2d:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0100f34:	00 
f0100f35:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0100f3c:	e8 85 f1 ff ff       	call   f01000c6 <_panic>
				assert(pgdir[i] & PTE_W);
f0100f41:	f6 c2 02             	test   $0x2,%dl
f0100f44:	75 4e                	jne    f0100f94 <check_kern_pgdir+0x2a5>
f0100f46:	c7 44 24 0c c0 5d 10 	movl   $0xf0105dc0,0xc(%esp)
f0100f4d:	f0 
f0100f4e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100f55:	f0 
f0100f56:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0100f5d:	00 
f0100f5e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0100f65:	e8 5c f1 ff ff       	call   f01000c6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100f6a:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100f6e:	74 24                	je     f0100f94 <check_kern_pgdir+0x2a5>
f0100f70:	c7 44 24 0c d1 5d 10 	movl   $0xf0105dd1,0xc(%esp)
f0100f77:	f0 
f0100f78:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0100f7f:	f0 
f0100f80:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0100f87:	00 
f0100f88:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0100fa2:	c7 04 24 10 57 10 f0 	movl   $0xf0105710,(%esp)
f0100fa9:	e8 44 27 00 00       	call   f01036f2 <cprintf>
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
f0100fcc:	c7 44 24 08 30 57 10 	movl   $0xf0105730,0x8(%esp)
f0100fd3:	f0 
f0100fd4:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100fdb:	00 
f0100fdc:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f010102a:	a3 1c 22 1a f0       	mov    %eax,0xf01a221c
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
f0101034:	8b 1d 1c 22 1a f0    	mov    0xf01a221c,%ebx
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
f0101064:	e8 2e 3b 00 00       	call   f0104b97 <memset>
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
f010107c:	8b 1d 1c 22 1a f0    	mov    0xf01a221c,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101082:	8b 35 ec 3e 1a f0    	mov    0xf01a3eec,%esi
		assert(pp < pages + npages);
f0101088:	a1 e4 3e 1a f0       	mov    0xf01a3ee4,%eax
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
f01010ab:	c7 44 24 0c df 5d 10 	movl   $0xf0105ddf,0xc(%esp)
f01010b2:	f0 
f01010b3:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01010ba:	f0 
f01010bb:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f01010c2:	00 
f01010c3:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01010ca:	e8 f7 ef ff ff       	call   f01000c6 <_panic>
		assert(pp < pages + npages);
f01010cf:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01010d2:	72 24                	jb     f01010f8 <check_page_free_list+0x142>
f01010d4:	c7 44 24 0c eb 5d 10 	movl   $0xf0105deb,0xc(%esp)
f01010db:	f0 
f01010dc:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01010e3:	f0 
f01010e4:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01010eb:	00 
f01010ec:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01010f3:	e8 ce ef ff ff       	call   f01000c6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010f8:	89 d8                	mov    %ebx,%eax
f01010fa:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01010fd:	a8 07                	test   $0x7,%al
f01010ff:	74 24                	je     f0101125 <check_page_free_list+0x16f>
f0101101:	c7 44 24 0c 54 57 10 	movl   $0xf0105754,0xc(%esp)
f0101108:	f0 
f0101109:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101110:	f0 
f0101111:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f0101118:	00 
f0101119:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101120:	e8 a1 ef ff ff       	call   f01000c6 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101125:	89 d8                	mov    %ebx,%eax
f0101127:	e8 97 f9 ff ff       	call   f0100ac3 <page2pa>
f010112c:	85 c0                	test   %eax,%eax
f010112e:	75 24                	jne    f0101154 <check_page_free_list+0x19e>
f0101130:	c7 44 24 0c ff 5d 10 	movl   $0xf0105dff,0xc(%esp)
f0101137:	f0 
f0101138:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010113f:	f0 
f0101140:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0101147:	00 
f0101148:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010114f:	e8 72 ef ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101154:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101159:	75 24                	jne    f010117f <check_page_free_list+0x1c9>
f010115b:	c7 44 24 0c 10 5e 10 	movl   $0xf0105e10,0xc(%esp)
f0101162:	f0 
f0101163:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010116a:	f0 
f010116b:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0101172:	00 
f0101173:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010117a:	e8 47 ef ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010117f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101184:	75 24                	jne    f01011aa <check_page_free_list+0x1f4>
f0101186:	c7 44 24 0c 88 57 10 	movl   $0xf0105788,0xc(%esp)
f010118d:	f0 
f010118e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101195:	f0 
f0101196:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f010119d:	00 
f010119e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01011a5:	e8 1c ef ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01011aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01011af:	75 24                	jne    f01011d5 <check_page_free_list+0x21f>
f01011b1:	c7 44 24 0c 29 5e 10 	movl   $0xf0105e29,0xc(%esp)
f01011b8:	f0 
f01011b9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01011c0:	f0 
f01011c1:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f01011c8:	00 
f01011c9:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01011d0:	e8 f1 ee ff ff       	call   f01000c6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01011d5:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01011da:	76 30                	jbe    f010120c <check_page_free_list+0x256>
f01011dc:	89 d8                	mov    %ebx,%eax
f01011de:	e8 d0 f9 ff ff       	call   f0100bb3 <page2kva>
f01011e3:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f01011e6:	76 29                	jbe    f0101211 <check_page_free_list+0x25b>
f01011e8:	c7 44 24 0c ac 57 10 	movl   $0xf01057ac,0xc(%esp)
f01011ef:	f0 
f01011f0:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01011f7:	f0 
f01011f8:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f01011ff:	00 
f0101200:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101223:	c7 44 24 0c 43 5e 10 	movl   $0xf0105e43,0xc(%esp)
f010122a:	f0 
f010122b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101232:	f0 
f0101233:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f010123a:	00 
f010123b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101242:	e8 7f ee ff ff       	call   f01000c6 <_panic>
	assert(nfree_extmem > 0);
f0101247:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f010124b:	7f 4e                	jg     f010129b <check_page_free_list+0x2e5>
f010124d:	c7 44 24 0c 55 5e 10 	movl   $0xf0105e55,0xc(%esp)
f0101254:	f0 
f0101255:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010125c:	f0 
f010125d:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101264:	00 
f0101265:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010126c:	e8 55 ee ff ff       	call   f01000c6 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101271:	8b 1d 1c 22 1a f0    	mov    0xf01a221c,%ebx
f0101277:	85 db                	test   %ebx,%ebx
f0101279:	0f 85 69 fd ff ff    	jne    f0100fe8 <check_page_free_list+0x32>
f010127f:	e9 48 fd ff ff       	jmp    f0100fcc <check_page_free_list+0x16>
f0101284:	83 3d 1c 22 1a f0 00 	cmpl   $0x0,0xf01a221c
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
f01012a6:	3b 05 e4 3e 1a f0    	cmp    0xf01a3ee4,%eax
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
f01012b4:	c7 44 24 08 f4 57 10 	movl   $0xf01057f4,0x8(%esp)
f01012bb:	f0 
f01012bc:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01012c3:	00 
f01012c4:	c7 04 24 6d 5d 10 f0 	movl   $0xf0105d6d,(%esp)
f01012cb:	e8 f6 ed ff ff       	call   f01000c6 <_panic>
	return &pages[PGNUM(pa)];
f01012d0:	8b 15 ec 3e 1a f0    	mov    0xf01a3eec,%edx
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
f01012f0:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f01012f5:	e8 43 f9 ff ff       	call   f0100c3d <_paddr>
f01012fa:	c1 e8 0c             	shr    $0xc,%eax
f01012fd:	8b 35 1c 22 1a f0    	mov    0xf01a221c,%esi
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
f010131f:	03 1d ec 3e 1a f0    	add    0xf01a3eec,%ebx
f0101325:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f010132b:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f010132d:	89 ce                	mov    %ecx,%esi
f010132f:	03 35 ec 3e 1a f0    	add    0xf01a3eec,%esi
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101335:	83 c2 01             	add    $0x1,%edx
f0101338:	3b 15 e4 3e 1a f0    	cmp    0xf01a3ee4,%edx
f010133e:	72 ca                	jb     f010130a <page_init+0x30>
f0101340:	89 35 1c 22 1a f0    	mov    %esi,0xf01a221c
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
f0101351:	8b 1d 1c 22 1a f0    	mov    0xf01a221c,%ebx
f0101357:	85 db                	test   %ebx,%ebx
f0101359:	74 36                	je     f0101391 <page_alloc+0x47>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f010135b:	8b 03                	mov    (%ebx),%eax
f010135d:	a3 1c 22 1a f0       	mov    %eax,0xf01a221c
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
f0101388:	e8 0a 38 00 00       	call   f0104b97 <memset>
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
f01013ac:	c7 44 24 08 66 5e 10 	movl   $0xf0105e66,0x8(%esp)
f01013b3:	f0 
f01013b4:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
f01013bb:	00 
f01013bc:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01013c3:	e8 fe ec ff ff       	call   f01000c6 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f01013c8:	83 38 00             	cmpl   $0x0,(%eax)
f01013cb:	74 1c                	je     f01013e9 <page_free+0x4d>
f01013cd:	c7 44 24 08 14 58 10 	movl   $0xf0105814,0x8(%esp)
f01013d4:	f0 
f01013d5:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f01013dc:	00 
f01013dd:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01013e4:	e8 dd ec ff ff       	call   f01000c6 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f01013e9:	8b 15 1c 22 1a f0    	mov    0xf01a221c,%edx
f01013ef:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f01013f1:	a3 1c 22 1a f0       	mov    %eax,0xf01a221c
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
f0101401:	83 3d ec 3e 1a f0 00 	cmpl   $0x0,0xf01a3eec
f0101408:	75 1c                	jne    f0101426 <check_page_alloc+0x2e>
		panic("'pages' is a null pointer!");
f010140a:	c7 44 24 08 7a 5e 10 	movl   $0xf0105e7a,0x8(%esp)
f0101411:	f0 
f0101412:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0101419:	00 
f010141a:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101421:	e8 a0 ec ff ff       	call   f01000c6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101426:	a1 1c 22 1a f0       	mov    0xf01a221c,%eax
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
f010144d:	c7 44 24 0c 95 5e 10 	movl   $0xf0105e95,0xc(%esp)
f0101454:	f0 
f0101455:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010145c:	f0 
f010145d:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0101464:	00 
f0101465:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010146c:	e8 55 ec ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101471:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101478:	e8 cd fe ff ff       	call   f010134a <page_alloc>
f010147d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101480:	85 c0                	test   %eax,%eax
f0101482:	75 24                	jne    f01014a8 <check_page_alloc+0xb0>
f0101484:	c7 44 24 0c ab 5e 10 	movl   $0xf0105eab,0xc(%esp)
f010148b:	f0 
f010148c:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101493:	f0 
f0101494:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f010149b:	00 
f010149c:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01014a3:	e8 1e ec ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f01014a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014af:	e8 96 fe ff ff       	call   f010134a <page_alloc>
f01014b4:	89 c3                	mov    %eax,%ebx
f01014b6:	85 c0                	test   %eax,%eax
f01014b8:	75 24                	jne    f01014de <check_page_alloc+0xe6>
f01014ba:	c7 44 24 0c c1 5e 10 	movl   $0xf0105ec1,0xc(%esp)
f01014c1:	f0 
f01014c2:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01014c9:	f0 
f01014ca:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f01014d1:	00 
f01014d2:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01014d9:	e8 e8 eb ff ff       	call   f01000c6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014de:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01014e1:	75 24                	jne    f0101507 <check_page_alloc+0x10f>
f01014e3:	c7 44 24 0c d7 5e 10 	movl   $0xf0105ed7,0xc(%esp)
f01014ea:	f0 
f01014eb:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01014f2:	f0 
f01014f3:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f01014fa:	00 
f01014fb:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101502:	e8 bf eb ff ff       	call   f01000c6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101507:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010150a:	74 04                	je     f0101510 <check_page_alloc+0x118>
f010150c:	39 f8                	cmp    %edi,%eax
f010150e:	75 24                	jne    f0101534 <check_page_alloc+0x13c>
f0101510:	c7 44 24 0c 40 58 10 	movl   $0xf0105840,0xc(%esp)
f0101517:	f0 
f0101518:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010151f:	f0 
f0101520:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0101527:	00 
f0101528:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010152f:	e8 92 eb ff ff       	call   f01000c6 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101534:	89 f8                	mov    %edi,%eax
f0101536:	e8 88 f5 ff ff       	call   f0100ac3 <page2pa>
f010153b:	8b 0d e4 3e 1a f0    	mov    0xf01a3ee4,%ecx
f0101541:	c1 e1 0c             	shl    $0xc,%ecx
f0101544:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101547:	39 c8                	cmp    %ecx,%eax
f0101549:	72 24                	jb     f010156f <check_page_alloc+0x177>
f010154b:	c7 44 24 0c e9 5e 10 	movl   $0xf0105ee9,0xc(%esp)
f0101552:	f0 
f0101553:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010155a:	f0 
f010155b:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101562:	00 
f0101563:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010156a:	e8 57 eb ff ff       	call   f01000c6 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010156f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101572:	e8 4c f5 ff ff       	call   f0100ac3 <page2pa>
f0101577:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010157a:	77 24                	ja     f01015a0 <check_page_alloc+0x1a8>
f010157c:	c7 44 24 0c 06 5f 10 	movl   $0xf0105f06,0xc(%esp)
f0101583:	f0 
f0101584:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010158b:	f0 
f010158c:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101593:	00 
f0101594:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010159b:	e8 26 eb ff ff       	call   f01000c6 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01015a0:	89 d8                	mov    %ebx,%eax
f01015a2:	e8 1c f5 ff ff       	call   f0100ac3 <page2pa>
f01015a7:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01015aa:	77 24                	ja     f01015d0 <check_page_alloc+0x1d8>
f01015ac:	c7 44 24 0c 23 5f 10 	movl   $0xf0105f23,0xc(%esp)
f01015b3:	f0 
f01015b4:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01015bb:	f0 
f01015bc:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
f01015c3:	00 
f01015c4:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01015cb:	e8 f6 ea ff ff       	call   f01000c6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015d0:	a1 1c 22 1a f0       	mov    0xf01a221c,%eax
f01015d5:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01015d8:	c7 05 1c 22 1a f0 00 	movl   $0x0,0xf01a221c
f01015df:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01015e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e9:	e8 5c fd ff ff       	call   f010134a <page_alloc>
f01015ee:	85 c0                	test   %eax,%eax
f01015f0:	74 24                	je     f0101616 <check_page_alloc+0x21e>
f01015f2:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f01015f9:	f0 
f01015fa:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101601:	f0 
f0101602:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0101609:	00 
f010160a:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101643:	c7 44 24 0c 95 5e 10 	movl   $0xf0105e95,0xc(%esp)
f010164a:	f0 
f010164b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101652:	f0 
f0101653:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f010165a:	00 
f010165b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101662:	e8 5f ea ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101667:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010166e:	e8 d7 fc ff ff       	call   f010134a <page_alloc>
f0101673:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101676:	85 c0                	test   %eax,%eax
f0101678:	75 24                	jne    f010169e <check_page_alloc+0x2a6>
f010167a:	c7 44 24 0c ab 5e 10 	movl   $0xf0105eab,0xc(%esp)
f0101681:	f0 
f0101682:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101689:	f0 
f010168a:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0101691:	00 
f0101692:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101699:	e8 28 ea ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f010169e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016a5:	e8 a0 fc ff ff       	call   f010134a <page_alloc>
f01016aa:	89 c7                	mov    %eax,%edi
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	75 24                	jne    f01016d4 <check_page_alloc+0x2dc>
f01016b0:	c7 44 24 0c c1 5e 10 	movl   $0xf0105ec1,0xc(%esp)
f01016b7:	f0 
f01016b8:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01016bf:	f0 
f01016c0:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f01016c7:	00 
f01016c8:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01016cf:	e8 f2 e9 ff ff       	call   f01000c6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016d4:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01016d7:	75 24                	jne    f01016fd <check_page_alloc+0x305>
f01016d9:	c7 44 24 0c d7 5e 10 	movl   $0xf0105ed7,0xc(%esp)
f01016e0:	f0 
f01016e1:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01016e8:	f0 
f01016e9:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f01016f0:	00 
f01016f1:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01016f8:	e8 c9 e9 ff ff       	call   f01000c6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016fd:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101700:	74 04                	je     f0101706 <check_page_alloc+0x30e>
f0101702:	39 d8                	cmp    %ebx,%eax
f0101704:	75 24                	jne    f010172a <check_page_alloc+0x332>
f0101706:	c7 44 24 0c 40 58 10 	movl   $0xf0105840,0xc(%esp)
f010170d:	f0 
f010170e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101715:	f0 
f0101716:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f010171d:	00 
f010171e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101725:	e8 9c e9 ff ff       	call   f01000c6 <_panic>
	assert(!page_alloc(0));
f010172a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101731:	e8 14 fc ff ff       	call   f010134a <page_alloc>
f0101736:	85 c0                	test   %eax,%eax
f0101738:	74 24                	je     f010175e <check_page_alloc+0x366>
f010173a:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f0101741:	f0 
f0101742:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101749:	f0 
f010174a:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0101751:	00 
f0101752:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101778:	e8 1a 34 00 00       	call   f0104b97 <memset>
	page_free(pp0);
f010177d:	89 1c 24             	mov    %ebx,(%esp)
f0101780:	e8 17 fc ff ff       	call   f010139c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101785:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010178c:	e8 b9 fb ff ff       	call   f010134a <page_alloc>
f0101791:	85 c0                	test   %eax,%eax
f0101793:	75 24                	jne    f01017b9 <check_page_alloc+0x3c1>
f0101795:	c7 44 24 0c 4f 5f 10 	movl   $0xf0105f4f,0xc(%esp)
f010179c:	f0 
f010179d:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01017a4:	f0 
f01017a5:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f01017ac:	00 
f01017ad:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01017b4:	e8 0d e9 ff ff       	call   f01000c6 <_panic>
	assert(pp && pp0 == pp);
f01017b9:	39 c3                	cmp    %eax,%ebx
f01017bb:	74 24                	je     f01017e1 <check_page_alloc+0x3e9>
f01017bd:	c7 44 24 0c 6d 5f 10 	movl   $0xf0105f6d,0xc(%esp)
f01017c4:	f0 
f01017c5:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01017cc:	f0 
f01017cd:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
f01017d4:	00 
f01017d5:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01017dc:	e8 e5 e8 ff ff       	call   f01000c6 <_panic>
	c = page2kva(pp);
f01017e1:	89 d8                	mov    %ebx,%eax
f01017e3:	e8 cb f3 ff ff       	call   f0100bb3 <page2kva>
	for (i = 0; i < PGSIZE; i++)
f01017e8:	ba 00 00 00 00       	mov    $0x0,%edx
		assert(c[i] == 0);
f01017ed:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01017f1:	74 24                	je     f0101817 <check_page_alloc+0x41f>
f01017f3:	c7 44 24 0c 7d 5f 10 	movl   $0xf0105f7d,0xc(%esp)
f01017fa:	f0 
f01017fb:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101802:	f0 
f0101803:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f010180a:	00 
f010180b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101825:	a3 1c 22 1a f0       	mov    %eax,0xf01a221c

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
f0101845:	a1 1c 22 1a f0       	mov    0xf01a221c,%eax
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
f0101859:	c7 44 24 0c 87 5f 10 	movl   $0xf0105f87,0xc(%esp)
f0101860:	f0 
f0101861:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101868:	f0 
f0101869:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101870:	00 
f0101871:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101878:	e8 49 e8 ff ff       	call   f01000c6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010187d:	c7 04 24 60 58 10 f0 	movl   $0xf0105860,(%esp)
f0101884:	e8 69 1e 00 00       	call   f01036f2 <cprintf>
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
f01018da:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
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
f010192b:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
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
f0101966:	c7 44 24 0c 92 5f 10 	movl   $0xf0105f92,0xc(%esp)
f010196d:	f0 
f010196e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101975:	f0 
f0101976:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010197d:	00 
f010197e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101985:	e8 3c e7 ff ff       	call   f01000c6 <_panic>
f010198a:	89 ce                	mov    %ecx,%esi
	assert(pa % PGSIZE == 0);
f010198c:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0101991:	74 24                	je     f01019b7 <boot_map_region+0x68>
f0101993:	c7 44 24 0c a3 5f 10 	movl   $0xf0105fa3,0xc(%esp)
f010199a:	f0 
f010199b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01019a2:	f0 
f01019a3:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f01019aa:	00 
f01019ab:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f01019d1:	c7 44 24 0c b4 5f 10 	movl   $0xf0105fb4,0xc(%esp)
f01019d8:	f0 
f01019d9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01019e0:	f0 
f01019e1:	c7 44 24 04 8c 01 00 	movl   $0x18c,0x4(%esp)
f01019e8:	00 
f01019e9:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101b5e:	c7 44 24 0c 95 5e 10 	movl   $0xf0105e95,0xc(%esp)
f0101b65:	f0 
f0101b66:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101b6d:	f0 
f0101b6e:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101b75:	00 
f0101b76:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101b7d:	e8 44 e5 ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b82:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b89:	e8 bc f7 ff ff       	call   f010134a <page_alloc>
f0101b8e:	89 c3                	mov    %eax,%ebx
f0101b90:	85 c0                	test   %eax,%eax
f0101b92:	75 24                	jne    f0101bb8 <check_page+0x76>
f0101b94:	c7 44 24 0c ab 5e 10 	movl   $0xf0105eab,0xc(%esp)
f0101b9b:	f0 
f0101b9c:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101bab:	00 
f0101bac:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101bb3:	e8 0e e5 ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bb8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bbf:	e8 86 f7 ff ff       	call   f010134a <page_alloc>
f0101bc4:	89 c6                	mov    %eax,%esi
f0101bc6:	85 c0                	test   %eax,%eax
f0101bc8:	75 24                	jne    f0101bee <check_page+0xac>
f0101bca:	c7 44 24 0c c1 5e 10 	movl   $0xf0105ec1,0xc(%esp)
f0101bd1:	f0 
f0101bd2:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101bd9:	f0 
f0101bda:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101be1:	00 
f0101be2:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101be9:	e8 d8 e4 ff ff       	call   f01000c6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101bee:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101bf1:	75 24                	jne    f0101c17 <check_page+0xd5>
f0101bf3:	c7 44 24 0c d7 5e 10 	movl   $0xf0105ed7,0xc(%esp)
f0101bfa:	f0 
f0101bfb:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101c02:	f0 
f0101c03:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0101c0a:	00 
f0101c0b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101c12:	e8 af e4 ff ff       	call   f01000c6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c17:	39 c3                	cmp    %eax,%ebx
f0101c19:	74 05                	je     f0101c20 <check_page+0xde>
f0101c1b:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
f0101c1e:	75 24                	jne    f0101c44 <check_page+0x102>
f0101c20:	c7 44 24 0c 40 58 10 	movl   $0xf0105840,0xc(%esp)
f0101c27:	f0 
f0101c28:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101c2f:	f0 
f0101c30:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101c37:	00 
f0101c38:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101c3f:	e8 82 e4 ff ff       	call   f01000c6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c44:	a1 1c 22 1a f0       	mov    0xf01a221c,%eax
f0101c49:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f0101c4c:	c7 05 1c 22 1a f0 00 	movl   $0x0,0xf01a221c
f0101c53:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c56:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c5d:	e8 e8 f6 ff ff       	call   f010134a <page_alloc>
f0101c62:	85 c0                	test   %eax,%eax
f0101c64:	74 24                	je     f0101c8a <check_page+0x148>
f0101c66:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f0101c6d:	f0 
f0101c6e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101c75:	f0 
f0101c76:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101c7d:	00 
f0101c7e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101c85:	e8 3c e4 ff ff       	call   f01000c6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c8a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c8d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c91:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101c98:	00 
f0101c99:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0101c9e:	89 04 24             	mov    %eax,(%esp)
f0101ca1:	e8 89 fd ff ff       	call   f0101a2f <page_lookup>
f0101ca6:	85 c0                	test   %eax,%eax
f0101ca8:	74 24                	je     f0101cce <check_page+0x18c>
f0101caa:	c7 44 24 0c 80 58 10 	movl   $0xf0105880,0xc(%esp)
f0101cb1:	f0 
f0101cb2:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101cb9:	f0 
f0101cba:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101cc1:	00 
f0101cc2:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101cc9:	e8 f8 e3 ff ff       	call   f01000c6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101cce:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cd5:	00 
f0101cd6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cdd:	00 
f0101cde:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ce2:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0101ce7:	89 04 24             	mov    %eax,(%esp)
f0101cea:	e8 e9 fd ff ff       	call   f0101ad8 <page_insert>
f0101cef:	85 c0                	test   %eax,%eax
f0101cf1:	78 24                	js     f0101d17 <check_page+0x1d5>
f0101cf3:	c7 44 24 0c b8 58 10 	movl   $0xf01058b8,0xc(%esp)
f0101cfa:	f0 
f0101cfb:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101d02:	f0 
f0101d03:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0101d0a:	00 
f0101d0b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101d36:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0101d3b:	89 04 24             	mov    %eax,(%esp)
f0101d3e:	e8 95 fd ff ff       	call   f0101ad8 <page_insert>
f0101d43:	85 c0                	test   %eax,%eax
f0101d45:	74 24                	je     f0101d6b <check_page+0x229>
f0101d47:	c7 44 24 0c e8 58 10 	movl   $0xf01058e8,0xc(%esp)
f0101d4e:	f0 
f0101d4f:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101d56:	f0 
f0101d57:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101d5e:	00 
f0101d5f:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101d66:	e8 5b e3 ff ff       	call   f01000c6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101d6b:	8b 3d e8 3e 1a f0    	mov    0xf01a3ee8,%edi
f0101d71:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d74:	e8 4a ed ff ff       	call   f0100ac3 <page2pa>
f0101d79:	8b 17                	mov    (%edi),%edx
f0101d7b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d81:	39 c2                	cmp    %eax,%edx
f0101d83:	74 24                	je     f0101da9 <check_page+0x267>
f0101d85:	c7 44 24 0c 18 59 10 	movl   $0xf0105918,0xc(%esp)
f0101d8c:	f0 
f0101d8d:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101d9c:	00 
f0101d9d:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101dc4:	c7 44 24 0c 40 59 10 	movl   $0xf0105940,0xc(%esp)
f0101dcb:	f0 
f0101dcc:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101dd3:	f0 
f0101dd4:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101ddb:	00 
f0101ddc:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101de3:	e8 de e2 ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 1);
f0101de8:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ded:	74 24                	je     f0101e13 <check_page+0x2d1>
f0101def:	c7 44 24 0c c7 5f 10 	movl   $0xf0105fc7,0xc(%esp)
f0101df6:	f0 
f0101df7:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101dfe:	f0 
f0101dff:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101e06:	00 
f0101e07:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101e0e:	e8 b3 e2 ff ff       	call   f01000c6 <_panic>
	assert(pp0->pp_ref == 1);
f0101e13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e16:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e1b:	74 24                	je     f0101e41 <check_page+0x2ff>
f0101e1d:	c7 44 24 0c d8 5f 10 	movl   $0xf0105fd8,0xc(%esp)
f0101e24:	f0 
f0101e25:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101e2c:	f0 
f0101e2d:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101e34:	00 
f0101e35:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0101e61:	c7 44 24 0c 70 59 10 	movl   $0xf0105970,0xc(%esp)
f0101e68:	f0 
f0101e69:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101e70:	f0 
f0101e71:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101e78:	00 
f0101e79:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101e80:	e8 41 e2 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e85:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e8a:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0101e8f:	e8 3d ed ff ff       	call   f0100bd1 <check_va2pa>
f0101e94:	89 c7                	mov    %eax,%edi
f0101e96:	89 f0                	mov    %esi,%eax
f0101e98:	e8 26 ec ff ff       	call   f0100ac3 <page2pa>
f0101e9d:	39 c7                	cmp    %eax,%edi
f0101e9f:	74 24                	je     f0101ec5 <check_page+0x383>
f0101ea1:	c7 44 24 0c ac 59 10 	movl   $0xf01059ac,0xc(%esp)
f0101ea8:	f0 
f0101ea9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101eb0:	f0 
f0101eb1:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101eb8:	00 
f0101eb9:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101ec0:	e8 01 e2 ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0101ec5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101eca:	74 24                	je     f0101ef0 <check_page+0x3ae>
f0101ecc:	c7 44 24 0c e9 5f 10 	movl   $0xf0105fe9,0xc(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101edb:	f0 
f0101edc:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101ee3:	00 
f0101ee4:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101eeb:	e8 d6 e1 ff ff       	call   f01000c6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ef0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ef7:	e8 4e f4 ff ff       	call   f010134a <page_alloc>
f0101efc:	85 c0                	test   %eax,%eax
f0101efe:	74 24                	je     f0101f24 <check_page+0x3e2>
f0101f00:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f0101f07:	f0 
f0101f08:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101f0f:	f0 
f0101f10:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101f17:	00 
f0101f18:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101f1f:	e8 a2 e1 ff ff       	call   f01000c6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f24:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f2b:	00 
f0101f2c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f33:	00 
f0101f34:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f38:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0101f3d:	89 04 24             	mov    %eax,(%esp)
f0101f40:	e8 93 fb ff ff       	call   f0101ad8 <page_insert>
f0101f45:	85 c0                	test   %eax,%eax
f0101f47:	74 24                	je     f0101f6d <check_page+0x42b>
f0101f49:	c7 44 24 0c 70 59 10 	movl   $0xf0105970,0xc(%esp)
f0101f50:	f0 
f0101f51:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101f58:	f0 
f0101f59:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0101f60:	00 
f0101f61:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101f68:	e8 59 e1 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f6d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f72:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0101f77:	e8 55 ec ff ff       	call   f0100bd1 <check_va2pa>
f0101f7c:	89 c7                	mov    %eax,%edi
f0101f7e:	89 f0                	mov    %esi,%eax
f0101f80:	e8 3e eb ff ff       	call   f0100ac3 <page2pa>
f0101f85:	39 c7                	cmp    %eax,%edi
f0101f87:	74 24                	je     f0101fad <check_page+0x46b>
f0101f89:	c7 44 24 0c ac 59 10 	movl   $0xf01059ac,0xc(%esp)
f0101f90:	f0 
f0101f91:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101f98:	f0 
f0101f99:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0101fa0:	00 
f0101fa1:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101fa8:	e8 19 e1 ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0101fad:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fb2:	74 24                	je     f0101fd8 <check_page+0x496>
f0101fb4:	c7 44 24 0c e9 5f 10 	movl   $0xf0105fe9,0xc(%esp)
f0101fbb:	f0 
f0101fbc:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101fc3:	f0 
f0101fc4:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101fcb:	00 
f0101fcc:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0101fd3:	e8 ee e0 ff ff       	call   f01000c6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101fd8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fdf:	e8 66 f3 ff ff       	call   f010134a <page_alloc>
f0101fe4:	85 c0                	test   %eax,%eax
f0101fe6:	74 24                	je     f010200c <check_page+0x4ca>
f0101fe8:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f0101fef:	f0 
f0101ff0:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0101fff:	00 
f0102000:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102007:	e8 ba e0 ff ff       	call   f01000c6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010200c:	8b 3d e8 3e 1a f0    	mov    0xf01a3ee8,%edi
f0102012:	8b 0f                	mov    (%edi),%ecx
f0102014:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010201a:	ba 5d 03 00 00       	mov    $0x35d,%edx
f010201f:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
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
f010204e:	c7 44 24 0c dc 59 10 	movl   $0xf01059dc,0xc(%esp)
f0102055:	f0 
f0102056:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010205d:	f0 
f010205e:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102065:	00 
f0102066:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010206d:	e8 54 e0 ff ff       	call   f01000c6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102072:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102079:	00 
f010207a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102081:	00 
f0102082:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102086:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f010208b:	89 04 24             	mov    %eax,(%esp)
f010208e:	e8 45 fa ff ff       	call   f0101ad8 <page_insert>
f0102093:	85 c0                	test   %eax,%eax
f0102095:	74 24                	je     f01020bb <check_page+0x579>
f0102097:	c7 44 24 0c 1c 5a 10 	movl   $0xf0105a1c,0xc(%esp)
f010209e:	f0 
f010209f:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01020a6:	f0 
f01020a7:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01020ae:	00 
f01020af:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01020b6:	e8 0b e0 ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020bb:	8b 3d e8 3e 1a f0    	mov    0xf01a3ee8,%edi
f01020c1:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020c6:	89 f8                	mov    %edi,%eax
f01020c8:	e8 04 eb ff ff       	call   f0100bd1 <check_va2pa>
f01020cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020d0:	89 f0                	mov    %esi,%eax
f01020d2:	e8 ec e9 ff ff       	call   f0100ac3 <page2pa>
f01020d7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020da:	74 24                	je     f0102100 <check_page+0x5be>
f01020dc:	c7 44 24 0c ac 59 10 	movl   $0xf01059ac,0xc(%esp)
f01020e3:	f0 
f01020e4:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01020eb:	f0 
f01020ec:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01020f3:	00 
f01020f4:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01020fb:	e8 c6 df ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0102100:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102105:	74 24                	je     f010212b <check_page+0x5e9>
f0102107:	c7 44 24 0c e9 5f 10 	movl   $0xf0105fe9,0xc(%esp)
f010210e:	f0 
f010210f:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102116:	f0 
f0102117:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f010211e:	00 
f010211f:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0102148:	c7 44 24 0c 5c 5a 10 	movl   $0xf0105a5c,0xc(%esp)
f010214f:	f0 
f0102150:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102157:	f0 
f0102158:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010215f:	00 
f0102160:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102167:	e8 5a df ff ff       	call   f01000c6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010216c:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102171:	f6 00 04             	testb  $0x4,(%eax)
f0102174:	75 24                	jne    f010219a <check_page+0x658>
f0102176:	c7 44 24 0c fa 5f 10 	movl   $0xf0105ffa,0xc(%esp)
f010217d:	f0 
f010217e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102185:	f0 
f0102186:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010218d:	00 
f010218e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f01021ba:	c7 44 24 0c 70 59 10 	movl   $0xf0105970,0xc(%esp)
f01021c1:	f0 
f01021c2:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01021d1:	00 
f01021d2:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01021d9:	e8 e8 de ff ff       	call   f01000c6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01021de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021e5:	00 
f01021e6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021ed:	00 
f01021ee:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f01021f3:	89 04 24             	mov    %eax,(%esp)
f01021f6:	e8 b9 f6 ff ff       	call   f01018b4 <pgdir_walk>
f01021fb:	f6 00 02             	testb  $0x2,(%eax)
f01021fe:	75 24                	jne    f0102224 <check_page+0x6e2>
f0102200:	c7 44 24 0c 90 5a 10 	movl   $0xf0105a90,0xc(%esp)
f0102207:	f0 
f0102208:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010220f:	f0 
f0102210:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102217:	00 
f0102218:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010221f:	e8 a2 de ff ff       	call   f01000c6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102224:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010222b:	00 
f010222c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102233:	00 
f0102234:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102239:	89 04 24             	mov    %eax,(%esp)
f010223c:	e8 73 f6 ff ff       	call   f01018b4 <pgdir_walk>
f0102241:	f6 00 04             	testb  $0x4,(%eax)
f0102244:	74 24                	je     f010226a <check_page+0x728>
f0102246:	c7 44 24 0c c4 5a 10 	movl   $0xf0105ac4,0xc(%esp)
f010224d:	f0 
f010224e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102255:	f0 
f0102256:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010225d:	00 
f010225e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102265:	e8 5c de ff ff       	call   f01000c6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010226a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102271:	00 
f0102272:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102279:	00 
f010227a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010227d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102281:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102286:	89 04 24             	mov    %eax,(%esp)
f0102289:	e8 4a f8 ff ff       	call   f0101ad8 <page_insert>
f010228e:	85 c0                	test   %eax,%eax
f0102290:	78 24                	js     f01022b6 <check_page+0x774>
f0102292:	c7 44 24 0c fc 5a 10 	movl   $0xf0105afc,0xc(%esp)
f0102299:	f0 
f010229a:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01022a1:	f0 
f01022a2:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01022a9:	00 
f01022aa:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01022b1:	e8 10 de ff ff       	call   f01000c6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01022b6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022bd:	00 
f01022be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022c5:	00 
f01022c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022ca:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f01022cf:	89 04 24             	mov    %eax,(%esp)
f01022d2:	e8 01 f8 ff ff       	call   f0101ad8 <page_insert>
f01022d7:	85 c0                	test   %eax,%eax
f01022d9:	74 24                	je     f01022ff <check_page+0x7bd>
f01022db:	c7 44 24 0c 34 5b 10 	movl   $0xf0105b34,0xc(%esp)
f01022e2:	f0 
f01022e3:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01022ea:	f0 
f01022eb:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f01022f2:	00 
f01022f3:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01022fa:	e8 c7 dd ff ff       	call   f01000c6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01022ff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102306:	00 
f0102307:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010230e:	00 
f010230f:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102314:	89 04 24             	mov    %eax,(%esp)
f0102317:	e8 98 f5 ff ff       	call   f01018b4 <pgdir_walk>
f010231c:	f6 00 04             	testb  $0x4,(%eax)
f010231f:	74 24                	je     f0102345 <check_page+0x803>
f0102321:	c7 44 24 0c c4 5a 10 	movl   $0xf0105ac4,0xc(%esp)
f0102328:	f0 
f0102329:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102330:	f0 
f0102331:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102338:	00 
f0102339:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102340:	e8 81 dd ff ff       	call   f01000c6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102345:	8b 3d e8 3e 1a f0    	mov    0xf01a3ee8,%edi
f010234b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102350:	89 f8                	mov    %edi,%eax
f0102352:	e8 7a e8 ff ff       	call   f0100bd1 <check_va2pa>
f0102357:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010235a:	89 d8                	mov    %ebx,%eax
f010235c:	e8 62 e7 ff ff       	call   f0100ac3 <page2pa>
f0102361:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102364:	74 24                	je     f010238a <check_page+0x848>
f0102366:	c7 44 24 0c 70 5b 10 	movl   $0xf0105b70,0xc(%esp)
f010236d:	f0 
f010236e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102375:	f0 
f0102376:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f010237d:	00 
f010237e:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102385:	e8 3c dd ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010238a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010238f:	89 f8                	mov    %edi,%eax
f0102391:	e8 3b e8 ff ff       	call   f0100bd1 <check_va2pa>
f0102396:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102399:	74 24                	je     f01023bf <check_page+0x87d>
f010239b:	c7 44 24 0c 9c 5b 10 	movl   $0xf0105b9c,0xc(%esp)
f01023a2:	f0 
f01023a3:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01023aa:	f0 
f01023ab:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f01023b2:	00 
f01023b3:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01023ba:	e8 07 dd ff ff       	call   f01000c6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01023bf:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01023c4:	74 24                	je     f01023ea <check_page+0x8a8>
f01023c6:	c7 44 24 0c 10 60 10 	movl   $0xf0106010,0xc(%esp)
f01023cd:	f0 
f01023ce:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01023d5:	f0 
f01023d6:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f01023dd:	00 
f01023de:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01023e5:	e8 dc dc ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 0);
f01023ea:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023ef:	74 24                	je     f0102415 <check_page+0x8d3>
f01023f1:	c7 44 24 0c 21 60 10 	movl   $0xf0106021,0xc(%esp)
f01023f8:	f0 
f01023f9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102400:	f0 
f0102401:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f0102408:	00 
f0102409:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f010242b:	c7 44 24 0c cc 5b 10 	movl   $0xf0105bcc,0xc(%esp)
f0102432:	f0 
f0102433:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010243a:	f0 
f010243b:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0102442:	00 
f0102443:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010244a:	e8 77 dc ff ff       	call   f01000c6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010244f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102456:	00 
f0102457:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f010245c:	89 04 24             	mov    %eax,(%esp)
f010245f:	e8 2b f6 ff ff       	call   f0101a8f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102464:	8b 35 e8 3e 1a f0    	mov    0xf01a3ee8,%esi
f010246a:	ba 00 00 00 00       	mov    $0x0,%edx
f010246f:	89 f0                	mov    %esi,%eax
f0102471:	e8 5b e7 ff ff       	call   f0100bd1 <check_va2pa>
f0102476:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102479:	74 24                	je     f010249f <check_page+0x95d>
f010247b:	c7 44 24 0c f0 5b 10 	movl   $0xf0105bf0,0xc(%esp)
f0102482:	f0 
f0102483:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010248a:	f0 
f010248b:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102492:	00 
f0102493:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f01024ba:	c7 44 24 0c 9c 5b 10 	movl   $0xf0105b9c,0xc(%esp)
f01024c1:	f0 
f01024c2:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01024c9:	f0 
f01024ca:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01024d1:	00 
f01024d2:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01024d9:	e8 e8 db ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 1);
f01024de:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024e3:	74 24                	je     f0102509 <check_page+0x9c7>
f01024e5:	c7 44 24 0c c7 5f 10 	movl   $0xf0105fc7,0xc(%esp)
f01024ec:	f0 
f01024ed:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01024f4:	f0 
f01024f5:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f01024fc:	00 
f01024fd:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102504:	e8 bd db ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 0);
f0102509:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010250e:	74 24                	je     f0102534 <check_page+0x9f2>
f0102510:	c7 44 24 0c 21 60 10 	movl   $0xf0106021,0xc(%esp)
f0102517:	f0 
f0102518:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010251f:	f0 
f0102520:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102527:	00 
f0102528:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f0102554:	c7 44 24 0c 14 5c 10 	movl   $0xf0105c14,0xc(%esp)
f010255b:	f0 
f010255c:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102563:	f0 
f0102564:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010256b:	00 
f010256c:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102573:	e8 4e db ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref);
f0102578:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010257d:	75 24                	jne    f01025a3 <check_page+0xa61>
f010257f:	c7 44 24 0c 32 60 10 	movl   $0xf0106032,0xc(%esp)
f0102586:	f0 
f0102587:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010258e:	f0 
f010258f:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102596:	00 
f0102597:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010259e:	e8 23 db ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_link == NULL);
f01025a3:	83 3b 00             	cmpl   $0x0,(%ebx)
f01025a6:	74 24                	je     f01025cc <check_page+0xa8a>
f01025a8:	c7 44 24 0c 3e 60 10 	movl   $0xf010603e,0xc(%esp)
f01025af:	f0 
f01025b0:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01025b7:	f0 
f01025b8:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01025bf:	00 
f01025c0:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01025c7:	e8 fa da ff ff       	call   f01000c6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025cc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025d3:	00 
f01025d4:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f01025d9:	89 04 24             	mov    %eax,(%esp)
f01025dc:	e8 ae f4 ff ff       	call   f0101a8f <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025e1:	8b 35 e8 3e 1a f0    	mov    0xf01a3ee8,%esi
f01025e7:	ba 00 00 00 00       	mov    $0x0,%edx
f01025ec:	89 f0                	mov    %esi,%eax
f01025ee:	e8 de e5 ff ff       	call   f0100bd1 <check_va2pa>
f01025f3:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025f6:	74 24                	je     f010261c <check_page+0xada>
f01025f8:	c7 44 24 0c f0 5b 10 	movl   $0xf0105bf0,0xc(%esp)
f01025ff:	f0 
f0102600:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102607:	f0 
f0102608:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f010260f:	00 
f0102610:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102617:	e8 aa da ff ff       	call   f01000c6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010261c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102621:	89 f0                	mov    %esi,%eax
f0102623:	e8 a9 e5 ff ff       	call   f0100bd1 <check_va2pa>
f0102628:	83 f8 ff             	cmp    $0xffffffff,%eax
f010262b:	74 24                	je     f0102651 <check_page+0xb0f>
f010262d:	c7 44 24 0c 4c 5c 10 	movl   $0xf0105c4c,0xc(%esp)
f0102634:	f0 
f0102635:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010263c:	f0 
f010263d:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102644:	00 
f0102645:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010264c:	e8 75 da ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 0);
f0102651:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102656:	74 24                	je     f010267c <check_page+0xb3a>
f0102658:	c7 44 24 0c 53 60 10 	movl   $0xf0106053,0xc(%esp)
f010265f:	f0 
f0102660:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102667:	f0 
f0102668:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010266f:	00 
f0102670:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102677:	e8 4a da ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 0);
f010267c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102681:	74 24                	je     f01026a7 <check_page+0xb65>
f0102683:	c7 44 24 0c 21 60 10 	movl   $0xf0106021,0xc(%esp)
f010268a:	f0 
f010268b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102692:	f0 
f0102693:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010269a:	00 
f010269b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f01026bd:	c7 44 24 0c 74 5c 10 	movl   $0xf0105c74,0xc(%esp)
f01026c4:	f0 
f01026c5:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01026cc:	f0 
f01026cd:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f01026d4:	00 
f01026d5:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f01026dc:	e8 e5 d9 ff ff       	call   f01000c6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01026e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026e8:	e8 5d ec ff ff       	call   f010134a <page_alloc>
f01026ed:	85 c0                	test   %eax,%eax
f01026ef:	74 24                	je     f0102715 <check_page+0xbd3>
f01026f1:	c7 44 24 0c 40 5f 10 	movl   $0xf0105f40,0xc(%esp)
f01026f8:	f0 
f01026f9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102700:	f0 
f0102701:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102708:	00 
f0102709:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102710:	e8 b1 d9 ff ff       	call   f01000c6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102715:	8b 1d e8 3e 1a f0    	mov    0xf01a3ee8,%ebx
f010271b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010271e:	e8 a0 e3 ff ff       	call   f0100ac3 <page2pa>
f0102723:	8b 13                	mov    (%ebx),%edx
f0102725:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010272b:	39 c2                	cmp    %eax,%edx
f010272d:	74 24                	je     f0102753 <check_page+0xc11>
f010272f:	c7 44 24 0c 18 59 10 	movl   $0xf0105918,0xc(%esp)
f0102736:	f0 
f0102737:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010273e:	f0 
f010273f:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102746:	00 
f0102747:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f010274e:	e8 73 d9 ff ff       	call   f01000c6 <_panic>
	kern_pgdir[0] = 0;
f0102753:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102759:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010275c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102761:	74 24                	je     f0102787 <check_page+0xc45>
f0102763:	c7 44 24 0c d8 5f 10 	movl   $0xf0105fd8,0xc(%esp)
f010276a:	f0 
f010276b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102772:	f0 
f0102773:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f010277a:	00 
f010277b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f01027a8:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f01027ad:	89 04 24             	mov    %eax,(%esp)
f01027b0:	e8 ff f0 ff ff       	call   f01018b4 <pgdir_walk>
f01027b5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01027b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01027bb:	8b 1d e8 3e 1a f0    	mov    0xf01a3ee8,%ebx
f01027c1:	8b 4b 04             	mov    0x4(%ebx),%ecx
f01027c4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01027ca:	ba a0 03 00 00       	mov    $0x3a0,%edx
f01027cf:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f01027d4:	e8 a2 e3 ff ff       	call   f0100b7b <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f01027d9:	83 c0 04             	add    $0x4,%eax
f01027dc:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01027df:	74 24                	je     f0102805 <check_page+0xcc3>
f01027e1:	c7 44 24 0c 64 60 10 	movl   $0xf0106064,0xc(%esp)
f01027e8:	f0 
f01027e9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01027f0:	f0 
f01027f1:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01027f8:	00 
f01027f9:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f010282f:	e8 63 23 00 00       	call   f0104b97 <memset>
	page_free(pp0);
f0102834:	89 1c 24             	mov    %ebx,(%esp)
f0102837:	e8 60 eb ff ff       	call   f010139c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010283c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102843:	00 
f0102844:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010284b:	00 
f010284c:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
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
f010286e:	c7 44 24 0c 7c 60 10 	movl   $0xf010607c,0xc(%esp)
f0102875:	f0 
f0102876:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010287d:	f0 
f010287e:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102885:	00 
f0102886:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f010289d:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f01028a2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01028a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028ab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01028b1:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01028b4:	89 0d 1c 22 1a f0    	mov    %ecx,0xf01a221c

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
f01028d2:	c7 04 24 93 60 10 f0 	movl   $0xf0106093,(%esp)
f01028d9:	e8 14 0e 00 00       	call   f01036f2 <cprintf>
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
f0102901:	c7 44 24 0c 95 5e 10 	movl   $0xf0105e95,0xc(%esp)
f0102908:	f0 
f0102909:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102910:	f0 
f0102911:	c7 44 24 04 c6 03 00 	movl   $0x3c6,0x4(%esp)
f0102918:	00 
f0102919:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102920:	e8 a1 d7 ff ff       	call   f01000c6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102925:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010292c:	e8 19 ea ff ff       	call   f010134a <page_alloc>
f0102931:	89 c7                	mov    %eax,%edi
f0102933:	85 c0                	test   %eax,%eax
f0102935:	75 24                	jne    f010295b <check_page_installed_pgdir+0x75>
f0102937:	c7 44 24 0c ab 5e 10 	movl   $0xf0105eab,0xc(%esp)
f010293e:	f0 
f010293f:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102946:	f0 
f0102947:	c7 44 24 04 c7 03 00 	movl   $0x3c7,0x4(%esp)
f010294e:	00 
f010294f:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102956:	e8 6b d7 ff ff       	call   f01000c6 <_panic>
	assert((pp2 = page_alloc(0)));
f010295b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102962:	e8 e3 e9 ff ff       	call   f010134a <page_alloc>
f0102967:	89 c3                	mov    %eax,%ebx
f0102969:	85 c0                	test   %eax,%eax
f010296b:	75 24                	jne    f0102991 <check_page_installed_pgdir+0xab>
f010296d:	c7 44 24 0c c1 5e 10 	movl   $0xf0105ec1,0xc(%esp)
f0102974:	f0 
f0102975:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010297c:	f0 
f010297d:	c7 44 24 04 c8 03 00 	movl   $0x3c8,0x4(%esp)
f0102984:	00 
f0102985:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
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
f01029b3:	e8 df 21 00 00       	call   f0104b97 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01029b8:	89 d8                	mov    %ebx,%eax
f01029ba:	e8 f4 e1 ff ff       	call   f0100bb3 <page2kva>
f01029bf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029c6:	00 
f01029c7:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01029ce:	00 
f01029cf:	89 04 24             	mov    %eax,(%esp)
f01029d2:	e8 c0 21 00 00       	call   f0104b97 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01029d7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029de:	00 
f01029df:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029e6:	00 
f01029e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01029eb:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f01029f0:	89 04 24             	mov    %eax,(%esp)
f01029f3:	e8 e0 f0 ff ff       	call   f0101ad8 <page_insert>
	assert(pp1->pp_ref == 1);
f01029f8:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029fd:	74 24                	je     f0102a23 <check_page_installed_pgdir+0x13d>
f01029ff:	c7 44 24 0c c7 5f 10 	movl   $0xf0105fc7,0xc(%esp)
f0102a06:	f0 
f0102a07:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102a0e:	f0 
f0102a0f:	c7 44 24 04 cd 03 00 	movl   $0x3cd,0x4(%esp)
f0102a16:	00 
f0102a17:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102a1e:	e8 a3 d6 ff ff       	call   f01000c6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102a23:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102a2a:	01 01 01 
f0102a2d:	74 24                	je     f0102a53 <check_page_installed_pgdir+0x16d>
f0102a2f:	c7 44 24 0c 98 5c 10 	movl   $0xf0105c98,0xc(%esp)
f0102a36:	f0 
f0102a37:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102a3e:	f0 
f0102a3f:	c7 44 24 04 ce 03 00 	movl   $0x3ce,0x4(%esp)
f0102a46:	00 
f0102a47:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102a4e:	e8 73 d6 ff ff       	call   f01000c6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102a53:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a5a:	00 
f0102a5b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a62:	00 
f0102a63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102a67:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102a6c:	89 04 24             	mov    %eax,(%esp)
f0102a6f:	e8 64 f0 ff ff       	call   f0101ad8 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102a74:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102a7b:	02 02 02 
f0102a7e:	74 24                	je     f0102aa4 <check_page_installed_pgdir+0x1be>
f0102a80:	c7 44 24 0c bc 5c 10 	movl   $0xf0105cbc,0xc(%esp)
f0102a87:	f0 
f0102a88:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102a8f:	f0 
f0102a90:	c7 44 24 04 d0 03 00 	movl   $0x3d0,0x4(%esp)
f0102a97:	00 
f0102a98:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102a9f:	e8 22 d6 ff ff       	call   f01000c6 <_panic>
	assert(pp2->pp_ref == 1);
f0102aa4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102aa9:	74 24                	je     f0102acf <check_page_installed_pgdir+0x1e9>
f0102aab:	c7 44 24 0c e9 5f 10 	movl   $0xf0105fe9,0xc(%esp)
f0102ab2:	f0 
f0102ab3:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102aba:	f0 
f0102abb:	c7 44 24 04 d1 03 00 	movl   $0x3d1,0x4(%esp)
f0102ac2:	00 
f0102ac3:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102aca:	e8 f7 d5 ff ff       	call   f01000c6 <_panic>
	assert(pp1->pp_ref == 0);
f0102acf:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ad4:	74 24                	je     f0102afa <check_page_installed_pgdir+0x214>
f0102ad6:	c7 44 24 0c 53 60 10 	movl   $0xf0106053,0xc(%esp)
f0102add:	f0 
f0102ade:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102ae5:	f0 
f0102ae6:	c7 44 24 04 d2 03 00 	movl   $0x3d2,0x4(%esp)
f0102aed:	00 
f0102aee:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102af5:	e8 cc d5 ff ff       	call   f01000c6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102afa:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b01:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b04:	89 d8                	mov    %ebx,%eax
f0102b06:	e8 a8 e0 ff ff       	call   f0100bb3 <page2kva>
f0102b0b:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102b11:	74 24                	je     f0102b37 <check_page_installed_pgdir+0x251>
f0102b13:	c7 44 24 0c e0 5c 10 	movl   $0xf0105ce0,0xc(%esp)
f0102b1a:	f0 
f0102b1b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102b22:	f0 
f0102b23:	c7 44 24 04 d4 03 00 	movl   $0x3d4,0x4(%esp)
f0102b2a:	00 
f0102b2b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102b32:	e8 8f d5 ff ff       	call   f01000c6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102b37:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b3e:	00 
f0102b3f:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102b44:	89 04 24             	mov    %eax,(%esp)
f0102b47:	e8 43 ef ff ff       	call   f0101a8f <page_remove>
	assert(pp2->pp_ref == 0);
f0102b4c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102b51:	74 24                	je     f0102b77 <check_page_installed_pgdir+0x291>
f0102b53:	c7 44 24 0c 21 60 10 	movl   $0xf0106021,0xc(%esp)
f0102b5a:	f0 
f0102b5b:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102b62:	f0 
f0102b63:	c7 44 24 04 d6 03 00 	movl   $0x3d6,0x4(%esp)
f0102b6a:	00 
f0102b6b:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102b72:	e8 4f d5 ff ff       	call   f01000c6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b77:	8b 1d e8 3e 1a f0    	mov    0xf01a3ee8,%ebx
f0102b7d:	89 f0                	mov    %esi,%eax
f0102b7f:	e8 3f df ff ff       	call   f0100ac3 <page2pa>
f0102b84:	8b 13                	mov    (%ebx),%edx
f0102b86:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102b8c:	39 c2                	cmp    %eax,%edx
f0102b8e:	74 24                	je     f0102bb4 <check_page_installed_pgdir+0x2ce>
f0102b90:	c7 44 24 0c 18 59 10 	movl   $0xf0105918,0xc(%esp)
f0102b97:	f0 
f0102b98:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102b9f:	f0 
f0102ba0:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102ba7:	00 
f0102ba8:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102baf:	e8 12 d5 ff ff       	call   f01000c6 <_panic>
	kern_pgdir[0] = 0;
f0102bb4:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102bba:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102bbf:	74 24                	je     f0102be5 <check_page_installed_pgdir+0x2ff>
f0102bc1:	c7 44 24 0c d8 5f 10 	movl   $0xf0105fd8,0xc(%esp)
f0102bc8:	f0 
f0102bc9:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0102bd0:	f0 
f0102bd1:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102bd8:	00 
f0102bd9:	c7 04 24 7b 5d 10 f0 	movl   $0xf0105d7b,(%esp)
f0102be0:	e8 e1 d4 ff ff       	call   f01000c6 <_panic>
	pp0->pp_ref = 0;
f0102be5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102beb:	89 34 24             	mov    %esi,(%esp)
f0102bee:	e8 a9 e7 ff ff       	call   f010139c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102bf3:	c7 04 24 0c 5d 10 f0 	movl   $0xf0105d0c,(%esp)
f0102bfa:	e8 f3 0a 00 00       	call   f01036f2 <cprintf>
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
f0102c1d:	a3 e8 3e 1a f0       	mov    %eax,0xf01a3ee8
	memset(kern_pgdir, 0, PGSIZE);
f0102c22:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c29:	00 
f0102c2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c31:	00 
f0102c32:	89 04 24             	mov    %eax,(%esp)
f0102c35:	e8 5d 1f 00 00       	call   f0104b97 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0102c3a:	8b 1d e8 3e 1a f0    	mov    0xf01a3ee8,%ebx
f0102c40:	89 d9                	mov    %ebx,%ecx
f0102c42:	ba 93 00 00 00       	mov    $0x93,%edx
f0102c47:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0102c4c:	e8 ec df ff ff       	call   f0100c3d <_paddr>
f0102c51:	83 c8 05             	or     $0x5,%eax
f0102c54:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102c5a:	a1 e4 3e 1a f0       	mov    0xf01a3ee4,%eax
f0102c5f:	c1 e0 03             	shl    $0x3,%eax
f0102c62:	e8 03 e0 ff ff       	call   f0100c6a <boot_alloc>
f0102c67:	a3 ec 3e 1a f0       	mov    %eax,0xf01a3eec
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102c6c:	8b 1d e4 3e 1a f0    	mov    0xf01a3ee4,%ebx
f0102c72:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102c79:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102c7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102c84:	00 
f0102c85:	89 04 24             	mov    %eax,(%esp)
f0102c88:	e8 0a 1f 00 00       	call   f0104b97 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f0102c8d:	b8 00 80 01 00       	mov    $0x18000,%eax
f0102c92:	e8 d3 df ff ff       	call   f0100c6a <boot_alloc>
f0102c97:	a3 28 22 1a f0       	mov    %eax,0xf01a2228
	memset(envs,0, NENV*sizeof(struct Env));
f0102c9c:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0102ca3:	00 
f0102ca4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102cab:	00 
f0102cac:	89 04 24             	mov    %eax,(%esp)
f0102caf:	e8 e3 1e 00 00       	call   f0104b97 <memset>
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
f0102ccd:	8b 0d ec 3e 1a f0    	mov    0xf01a3eec,%ecx
f0102cd3:	ba bd 00 00 00       	mov    $0xbd,%edx
f0102cd8:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0102cdd:	e8 5b df ff ff       	call   f0100c3d <_paddr>
f0102ce2:	8b 1d e4 3e 1a f0    	mov    0xf01a3ee4,%ebx
f0102ce8:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102cef:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102cf6:	00 
f0102cf7:	89 04 24             	mov    %eax,(%esp)
f0102cfa:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102cff:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102d04:	e8 46 ec ff ff       	call   f010194f <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f0102d09:	8b 0d 28 22 1a f0    	mov    0xf01a2228,%ecx
f0102d0f:	ba c5 00 00 00       	mov    $0xc5,%edx
f0102d14:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0102d19:	e8 1f df ff ff       	call   f0100c3d <_paddr>
f0102d1e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d25:	00 
f0102d26:	89 04 24             	mov    %eax,(%esp)
f0102d29:	b9 00 80 01 00       	mov    $0x18000,%ecx
f0102d2e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102d33:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
f0102d38:	e8 12 ec ff ff       	call   f010194f <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f0102d3d:	b9 00 70 10 f0       	mov    $0xf0107000,%ecx
f0102d42:	ba d2 00 00 00       	mov    $0xd2,%edx
f0102d47:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
f0102d4c:	e8 ec de ff ff       	call   f0100c3d <_paddr>
f0102d51:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102d58:	00 
f0102d59:	89 04 24             	mov    %eax,(%esp)
f0102d5c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102d61:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102d66:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
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
f0102d89:	a1 e8 3e 1a f0       	mov    0xf01a3ee8,%eax
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
f0102d98:	8b 0d e8 3e 1a f0    	mov    0xf01a3ee8,%ecx
f0102d9e:	ba e7 00 00 00       	mov    $0xe7,%edx
f0102da3:	b8 7b 5d 10 f0       	mov    $0xf0105d7b,%eax
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
f0102e20:	c7 04 24 38 5d 10 f0 	movl   $0xf0105d38,(%esp)
f0102e27:	e8 c6 08 00 00       	call   f01036f2 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102e2c:	89 1c 24             	mov    %ebx,(%esp)
f0102e2f:	e8 24 07 00 00       	call   f0103558 <env_destroy>
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
f0102e5d:	2b 05 ec 3e 1a f0    	sub    0xf01a3eec,%eax
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
f0102e77:	3b 1d e4 3e 1a f0    	cmp    0xf01a3ee4,%ebx
f0102e7d:	72 18                	jb     f0102e97 <_kaddr+0x2c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e7f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102e83:	c7 44 24 08 c0 55 10 	movl   $0xf01055c0,0x8(%esp)
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
f0102eb5:	b8 6d 5d 10 f0       	mov    $0xf0105d6d,%eax
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
f0102ed3:	c7 44 24 08 e4 55 10 	movl   $0xf01055e4,0x8(%esp)
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
f0102f1a:	8b 15 e8 3e 1a f0    	mov    0xf01a3ee8,%edx
f0102f20:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102f24:	89 04 24             	mov    %eax,(%esp)
f0102f27:	e8 21 1d 00 00       	call   f0104c4d <memcpy>
	p->pp_ref ++;
f0102f2c:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102f31:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102f34:	89 d9                	mov    %ebx,%ecx
f0102f36:	ba c2 00 00 00       	mov    $0xc2,%edx
f0102f3b:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
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
f0102f64:	3b 05 e4 3e 1a f0    	cmp    0xf01a3ee4,%eax
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
f0102f72:	c7 44 24 08 f4 57 10 	movl   $0xf01057f4,0x8(%esp)
f0102f79:	f0 
f0102f7a:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0102f81:	00 
f0102f82:	c7 04 24 6d 5d 10 f0 	movl   $0xf0105d6d,(%esp)
f0102f89:	e8 38 d1 ff ff       	call   f01000c6 <_panic>
	return &pages[PGNUM(pa)];
f0102f8e:	8b 15 ec 3e 1a f0    	mov    0xf01a3eec,%edx
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
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	va = ROUNDDOWN(va,PGSIZE);
f0102fa3:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102fa9:	89 d6                	mov    %edx,%esi
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f0102fab:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0102fb2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102fb7:	89 c1                	mov    %eax,%ecx
f0102fb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (va_finish>va) {
		len = va_finish - va; //es un multiplo de PGSIZE	
f0102fbc:	29 d0                	sub    %edx,%eax
f0102fbe:	89 d3                	mov    %edx,%ebx
f0102fc0:	f7 db                	neg    %ebx
f0102fc2:	39 ca                	cmp    %ecx,%edx
f0102fc4:	0f 42 d8             	cmovb  %eax,%ebx
f0102fc7:	eb 74                	jmp    f010303d <region_alloc+0xa5>
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	while (len>0){
		struct PageInfo* page = page_alloc(0);//no hay que inicializar
f0102fc9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102fd0:	e8 75 e3 ff ff       	call   f010134a <page_alloc>
		if (page == NULL) panic("Error allocating environment");
f0102fd5:	85 c0                	test   %eax,%eax
f0102fd7:	75 1c                	jne    f0102ff5 <region_alloc+0x5d>
f0102fd9:	c7 44 24 08 ed 60 10 	movl   $0xf01060ed,0x8(%esp)
f0102fe0:	f0 
f0102fe1:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
f0102fe8:	00 
f0102fe9:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f0102ff0:	e8 d1 d0 ff ff       	call   f01000c6 <_panic>

		int ret_code = page_insert(e->env_pgdir, page, va, PTE_W | PTE_U);
f0102ff5:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102ffc:	00 
f0102ffd:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103001:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103005:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103008:	89 04 24             	mov    %eax,(%esp)
f010300b:	e8 c8 ea ff ff       	call   f0101ad8 <page_insert>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
f0103010:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0103013:	75 1c                	jne    f0103031 <region_alloc+0x99>
f0103015:	c7 44 24 08 ed 60 10 	movl   $0xf01060ed,0x8(%esp)
f010301c:	f0 
f010301d:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
f0103024:	00 
f0103025:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f010302c:	e8 95 d0 ff ff       	call   f01000c6 <_panic>
		
		va+=PGSIZE;
f0103031:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len-=PGSIZE;
f0103037:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
		len = va_finish - va; //es un multiplo de PGSIZE	
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	while (len>0){
f010303d:	85 db                	test   %ebx,%ebx
f010303f:	75 88                	jne    f0102fc9 <region_alloc+0x31>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
		
		va+=PGSIZE;
		len-=PGSIZE;
	}
	assert(va==va_finish);
f0103041:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0103044:	74 24                	je     f010306a <region_alloc+0xd2>
f0103046:	c7 44 24 0c 0a 61 10 	movl   $0xf010610a,0xc(%esp)
f010304d:	f0 
f010304e:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0103055:	f0 
f0103056:	c7 44 24 04 2a 01 00 	movl   $0x12a,0x4(%esp)
f010305d:	00 
f010305e:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f0103065:	e8 5c d0 ff ff       	call   f01000c6 <_panic>
}
f010306a:	83 c4 2c             	add    $0x2c,%esp
f010306d:	5b                   	pop    %ebx
f010306e:	5e                   	pop    %esi
f010306f:	5f                   	pop    %edi
f0103070:	5d                   	pop    %ebp
f0103071:	c3                   	ret    

f0103072 <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f0103072:	55                   	push   %ebp
f0103073:	89 e5                	mov    %esp,%ebp
f0103075:	57                   	push   %edi
f0103076:	56                   	push   %esi
f0103077:	53                   	push   %ebx
f0103078:	83 ec 2c             	sub    $0x2c,%esp
f010307b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010307e:	89 d7                	mov    %edx,%edi
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	
	assert(rcr3()==PADDR(kern_pgdir));
f0103080:	e8 cd fd ff ff       	call   f0102e52 <rcr3>
f0103085:	89 c3                	mov    %eax,%ebx
f0103087:	8b 0d e8 3e 1a f0    	mov    0xf01a3ee8,%ecx
f010308d:	ba 64 01 00 00       	mov    $0x164,%edx
f0103092:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f0103097:	e8 25 fe ff ff       	call   f0102ec1 <_paddr>
f010309c:	39 c3                	cmp    %eax,%ebx
f010309e:	74 24                	je     f01030c4 <load_icode+0x52>
f01030a0:	c7 44 24 0c 18 61 10 	movl   $0xf0106118,0xc(%esp)
f01030a7:	f0 
f01030a8:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01030af:	f0 
f01030b0:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
f01030b7:	00 
f01030b8:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f01030bf:	e8 02 d0 ff ff       	call   f01000c6 <_panic>
	lcr3(PADDR(e->env_pgdir));//cambio a pgdir del env para que anden memcpy y memset
f01030c4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01030c7:	8b 4e 5c             	mov    0x5c(%esi),%ecx
f01030ca:	ba 65 01 00 00       	mov    $0x165,%edx
f01030cf:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f01030d4:	e8 e8 fd ff ff       	call   f0102ec1 <_paddr>
f01030d9:	e8 6c fd ff ff       	call   f0102e4a <lcr3>
	assert(rcr3()==PADDR(e->env_pgdir));
f01030de:	e8 6f fd ff ff       	call   f0102e52 <rcr3>
f01030e3:	89 c3                	mov    %eax,%ebx
f01030e5:	8b 4e 5c             	mov    0x5c(%esi),%ecx
f01030e8:	ba 66 01 00 00       	mov    $0x166,%edx
f01030ed:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f01030f2:	e8 ca fd ff ff       	call   f0102ec1 <_paddr>
f01030f7:	39 c3                	cmp    %eax,%ebx
f01030f9:	74 24                	je     f010311f <load_icode+0xad>
f01030fb:	c7 44 24 0c 32 61 10 	movl   $0xf0106132,0xc(%esp)
f0103102:	f0 
f0103103:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010310a:	f0 
f010310b:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
f0103112:	00 
f0103113:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f010311a:	e8 a7 cf ff ff       	call   f01000c6 <_panic>

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f010311f:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103125:	74 1c                	je     f0103143 <load_icode+0xd1>
f0103127:	c7 44 24 08 4e 61 10 	movl   $0xf010614e,0x8(%esp)
f010312e:	f0 
f010312f:	c7 44 24 04 69 01 00 	movl   $0x169,0x4(%esp)
f0103136:	00 
f0103137:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f010313e:	e8 83 cf ff ff       	call   f01000c6 <_panic>

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f0103143:	89 fe                	mov    %edi,%esi
f0103145:	03 77 1c             	add    0x1c(%edi),%esi
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f0103148:	bb 00 00 00 00       	mov    $0x0,%ebx
f010314d:	eb 58                	jmp    f01031a7 <load_icode+0x135>
		va=(void*) ph->p_va;
f010314f:	8b 46 08             	mov    0x8(%esi),%eax
f0103152:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		if (ph->p_type != ELF_PROG_LOAD) continue;
f0103155:	83 3e 01             	cmpl   $0x1,(%esi)
f0103158:	75 4a                	jne    f01031a4 <load_icode+0x132>
		region_alloc(e,va,ph->p_memsz);
f010315a:	8b 4e 14             	mov    0x14(%esi),%ecx
f010315d:	89 c2                	mov    %eax,%edx
f010315f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103162:	e8 31 fe ff ff       	call   f0102f98 <region_alloc>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);
f0103167:	8b 46 10             	mov    0x10(%esi),%eax
f010316a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010316e:	89 f8                	mov    %edi,%eax
f0103170:	03 46 04             	add    0x4(%esi),%eax
f0103173:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103177:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010317a:	89 04 24             	mov    %eax,(%esp)
f010317d:	e8 cb 1a 00 00       	call   f0104c4d <memcpy>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f0103182:	8b 46 10             	mov    0x10(%esi),%eax
f0103185:	8b 56 14             	mov    0x14(%esi),%edx
f0103188:	29 c2                	sub    %eax,%edx
f010318a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010318e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103195:	00 
f0103196:	03 45 e4             	add    -0x1c(%ebp),%eax
f0103199:	89 04 24             	mov    %eax,(%esp)
f010319c:	e8 f6 19 00 00       	call   f0104b97 <memset>
		ph++;
f01031a1:	83 c6 20             	add    $0x20,%esi
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f01031a4:	83 c3 01             	add    $0x1,%ebx
f01031a7:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f01031ab:	39 c3                	cmp    %eax,%ebx
f01031ad:	7c a0                	jl     f010314f <load_icode+0xdd>
		ph++;
		//ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f01031af:	8b 47 18             	mov    0x18(%edi),%eax
f01031b2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01031b5:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)USTACKTOP - PGSIZE,PGSIZE);
f01031b8:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01031bd:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01031c2:	89 f8                	mov    %edi,%eax
f01031c4:	e8 cf fd ff ff       	call   f0102f98 <region_alloc>

	lcr3(PADDR(kern_pgdir));//vuelvo a poner el pgdir del kernel 
f01031c9:	8b 0d e8 3e 1a f0    	mov    0xf01a3ee8,%ecx
f01031cf:	ba 81 01 00 00       	mov    $0x181,%edx
f01031d4:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f01031d9:	e8 e3 fc ff ff       	call   f0102ec1 <_paddr>
f01031de:	e8 67 fc ff ff       	call   f0102e4a <lcr3>
}
f01031e3:	83 c4 2c             	add    $0x2c,%esp
f01031e6:	5b                   	pop    %ebx
f01031e7:	5e                   	pop    %esi
f01031e8:	5f                   	pop    %edi
f01031e9:	5d                   	pop    %ebp
f01031ea:	c3                   	ret    

f01031eb <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01031eb:	55                   	push   %ebp
f01031ec:	89 e5                	mov    %esp,%ebp
f01031ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01031f1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01031f4:	85 c0                	test   %eax,%eax
f01031f6:	75 11                	jne    f0103209 <envid2env+0x1e>
		*env_store = curenv;
f01031f8:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f01031fd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103200:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103202:	b8 00 00 00 00       	mov    $0x0,%eax
f0103207:	eb 5e                	jmp    f0103267 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103209:	89 c2                	mov    %eax,%edx
f010320b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103211:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103214:	c1 e2 05             	shl    $0x5,%edx
f0103217:	03 15 28 22 1a f0    	add    0xf01a2228,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010321d:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103221:	74 05                	je     f0103228 <envid2env+0x3d>
f0103223:	39 42 48             	cmp    %eax,0x48(%edx)
f0103226:	74 10                	je     f0103238 <envid2env+0x4d>
		*env_store = 0;
f0103228:	8b 45 0c             	mov    0xc(%ebp),%eax
f010322b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103231:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103236:	eb 2f                	jmp    f0103267 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103238:	84 c9                	test   %cl,%cl
f010323a:	74 21                	je     f010325d <envid2env+0x72>
f010323c:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103241:	39 c2                	cmp    %eax,%edx
f0103243:	74 18                	je     f010325d <envid2env+0x72>
f0103245:	8b 40 48             	mov    0x48(%eax),%eax
f0103248:	39 42 4c             	cmp    %eax,0x4c(%edx)
f010324b:	74 10                	je     f010325d <envid2env+0x72>
		*env_store = 0;
f010324d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103250:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103256:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010325b:	eb 0a                	jmp    f0103267 <envid2env+0x7c>
	}

	*env_store = e;
f010325d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103260:	89 10                	mov    %edx,(%eax)
	return 0;
f0103262:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103267:	5d                   	pop    %ebp
f0103268:	c3                   	ret    

f0103269 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103269:	55                   	push   %ebp
f010326a:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f010326c:	b8 00 03 11 f0       	mov    $0xf0110300,%eax
f0103271:	e8 c4 fb ff ff       	call   f0102e3a <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f0103276:	b8 23 00 00 00       	mov    $0x23,%eax
f010327b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f010327d:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f010327f:	b0 10                	mov    $0x10,%al
f0103281:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f0103283:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0103285:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0103287:	ea 8e 32 10 f0 08 00 	ljmp   $0x8,$0xf010328e
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f010328e:	b0 00                	mov    $0x0,%al
f0103290:	e8 ad fb ff ff       	call   f0102e42 <lldt>
}
f0103295:	5d                   	pop    %ebp
f0103296:	c3                   	ret    

f0103297 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103297:	a1 28 22 1a f0       	mov    0xf01a2228,%eax
f010329c:	83 c0 60             	add    $0x60,%eax
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
		envs[i].env_status = ENV_FREE; 
f010329f:	ba ff 03 00 00       	mov    $0x3ff,%edx
f01032a4:	c7 40 f4 00 00 00 00 	movl   $0x0,-0xc(%eax)
		envs[i].env_id = 0;
f01032ab:	c7 40 e8 00 00 00 00 	movl   $0x0,-0x18(%eax)
		envs[i].env_link = &envs[i+1];
f01032b2:	89 40 e4             	mov    %eax,-0x1c(%eax)
f01032b5:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
f01032b8:	83 ea 01             	sub    $0x1,%edx
f01032bb:	75 e7                	jne    f01032a4 <env_init+0xd>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01032bd:	55                   	push   %ebp
f01032be:	89 e5                	mov    %esp,%ebp
		envs[i].env_status = ENV_FREE; 
		envs[i].env_id = 0;
		envs[i].env_link = &envs[i+1];
		
	}
	envs[NENV-1].env_status = ENV_FREE;
f01032c0:	a1 28 22 1a f0       	mov    0xf01a2228,%eax
f01032c5:	c7 80 f4 7f 01 00 00 	movl   $0x0,0x17ff4(%eax)
f01032cc:	00 00 00 
	envs[NENV-1].env_id = 0;
f01032cf:	c7 80 e8 7f 01 00 00 	movl   $0x0,0x17fe8(%eax)
f01032d6:	00 00 00 
	env_free_list = &envs[0];
f01032d9:	a3 2c 22 1a f0       	mov    %eax,0xf01a222c
	// Per-CPU part of the initialization
	env_init_percpu();
f01032de:	e8 86 ff ff ff       	call   f0103269 <env_init_percpu>
}
f01032e3:	5d                   	pop    %ebp
f01032e4:	c3                   	ret    

f01032e5 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01032e5:	55                   	push   %ebp
f01032e6:	89 e5                	mov    %esp,%ebp
f01032e8:	53                   	push   %ebx
f01032e9:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01032ec:	8b 1d 2c 22 1a f0    	mov    0xf01a222c,%ebx
f01032f2:	85 db                	test   %ebx,%ebx
f01032f4:	0f 84 ca 00 00 00    	je     f01033c4 <env_alloc+0xdf>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f01032fa:	89 d8                	mov    %ebx,%eax
f01032fc:	e8 ed fb ff ff       	call   f0102eee <env_setup_vm>
f0103301:	85 c0                	test   %eax,%eax
f0103303:	0f 88 c0 00 00 00    	js     f01033c9 <env_alloc+0xe4>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103309:	8b 43 48             	mov    0x48(%ebx),%eax
f010330c:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f0103311:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103316:	ba 00 10 00 00       	mov    $0x1000,%edx
f010331b:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010331e:	89 da                	mov    %ebx,%edx
f0103320:	2b 15 28 22 1a f0    	sub    0xf01a2228,%edx
f0103326:	c1 fa 05             	sar    $0x5,%edx
f0103329:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010332f:	09 d0                	or     %edx,%eax
f0103331:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103334:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103337:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010333a:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103341:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103348:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010334f:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103356:	00 
f0103357:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010335e:	00 
f010335f:	89 1c 24             	mov    %ebx,(%esp)
f0103362:	e8 30 18 00 00       	call   f0104b97 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103367:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010336d:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103373:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103379:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103380:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103386:	8b 43 44             	mov    0x44(%ebx),%eax
f0103389:	a3 2c 22 1a f0       	mov    %eax,0xf01a222c
	*newenv_store = e; 
f010338e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103391:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103393:	8b 53 48             	mov    0x48(%ebx),%edx
f0103396:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f010339b:	85 c0                	test   %eax,%eax
f010339d:	74 05                	je     f01033a4 <env_alloc+0xbf>
f010339f:	8b 40 48             	mov    0x48(%eax),%eax
f01033a2:	eb 05                	jmp    f01033a9 <env_alloc+0xc4>
f01033a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01033a9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01033ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033b1:	c7 04 24 5d 61 10 f0 	movl   $0xf010615d,(%esp)
f01033b8:	e8 35 03 00 00       	call   f01036f2 <cprintf>
	return 0;
f01033bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01033c2:	eb 05                	jmp    f01033c9 <env_alloc+0xe4>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01033c4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01033c9:	83 c4 14             	add    $0x14,%esp
f01033cc:	5b                   	pop    %ebx
f01033cd:	5d                   	pop    %ebp
f01033ce:	c3                   	ret    

f01033cf <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01033cf:	55                   	push   %ebp
f01033d0:	89 e5                	mov    %esp,%ebp
f01033d2:	83 ec 28             	sub    $0x28,%esp
	// LAB 3: Your code here.
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f01033d5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01033dc:	00 
f01033dd:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01033e0:	89 04 24             	mov    %eax,(%esp)
f01033e3:	e8 fd fe ff ff       	call   f01032e5 <env_alloc>
	if (err<0) panic("env_create: %e", err);
f01033e8:	85 c0                	test   %eax,%eax
f01033ea:	79 20                	jns    f010340c <env_create+0x3d>
f01033ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033f0:	c7 44 24 08 72 61 10 	movl   $0xf0106172,0x8(%esp)
f01033f7:	f0 
f01033f8:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f01033ff:	00 
f0103400:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f0103407:	e8 ba cc ff ff       	call   f01000c6 <_panic>
	load_icode(e,binary);
f010340c:	8b 55 08             	mov    0x8(%ebp),%edx
f010340f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103412:	e8 5b fc ff ff       	call   f0103072 <load_icode>
	e->env_type = type;
f0103417:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010341a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010341d:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103420:	c9                   	leave  
f0103421:	c3                   	ret    

f0103422 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103422:	55                   	push   %ebp
f0103423:	89 e5                	mov    %esp,%ebp
f0103425:	57                   	push   %edi
f0103426:	56                   	push   %esi
f0103427:	53                   	push   %ebx
f0103428:	83 ec 2c             	sub    $0x2c,%esp
f010342b:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010342e:	3b 3d 24 22 1a f0    	cmp    0xf01a2224,%edi
f0103434:	75 1a                	jne    f0103450 <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f0103436:	8b 0d e8 3e 1a f0    	mov    0xf01a3ee8,%ecx
f010343c:	ba a4 01 00 00       	mov    $0x1a4,%edx
f0103441:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f0103446:	e8 76 fa ff ff       	call   f0102ec1 <_paddr>
f010344b:	e8 fa f9 ff ff       	call   f0102e4a <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103450:	8b 57 48             	mov    0x48(%edi),%edx
f0103453:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103458:	85 c0                	test   %eax,%eax
f010345a:	74 05                	je     f0103461 <env_free+0x3f>
f010345c:	8b 40 48             	mov    0x48(%eax),%eax
f010345f:	eb 05                	jmp    f0103466 <env_free+0x44>
f0103461:	b8 00 00 00 00       	mov    $0x0,%eax
f0103466:	89 54 24 08          	mov    %edx,0x8(%esp)
f010346a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010346e:	c7 04 24 81 61 10 f0 	movl   $0xf0106181,(%esp)
f0103475:	e8 78 02 00 00       	call   f01036f2 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010347a:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103481:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0103484:	89 d0                	mov    %edx,%eax
f0103486:	c1 e0 02             	shl    $0x2,%eax
f0103489:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010348c:	8b 47 5c             	mov    0x5c(%edi),%eax
f010348f:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0103492:	a8 01                	test   $0x1,%al
f0103494:	74 6e                	je     f0103504 <env_free+0xe2>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103496:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010349b:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f010349e:	89 c1                	mov    %eax,%ecx
f01034a0:	ba b2 01 00 00       	mov    $0x1b2,%edx
f01034a5:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f01034aa:	e8 bc f9 ff ff       	call   f0102e6b <_kaddr>
f01034af:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034b4:	c1 e0 16             	shl    $0x16,%eax
f01034b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034ba:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01034bf:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f01034c3:	74 17                	je     f01034dc <env_free+0xba>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034c5:	89 d8                	mov    %ebx,%eax
f01034c7:	c1 e0 0c             	shl    $0xc,%eax
f01034ca:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034d1:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034d4:	89 04 24             	mov    %eax,(%esp)
f01034d7:	e8 b3 e5 ff ff       	call   f0101a8f <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034dc:	83 c3 01             	add    $0x1,%ebx
f01034df:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034e5:	75 d8                	jne    f01034bf <env_free+0x9d>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034e7:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034ea:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01034ed:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f01034f4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01034f7:	e8 65 fa ff ff       	call   f0102f61 <pa2page>
f01034fc:	89 04 24             	mov    %eax,(%esp)
f01034ff:	e8 8d e3 ff ff       	call   f0101891 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103504:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103508:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f010350f:	0f 85 6c ff ff ff    	jne    f0103481 <env_free+0x5f>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103515:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f0103518:	ba c0 01 00 00       	mov    $0x1c0,%edx
f010351d:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f0103522:	e8 9a f9 ff ff       	call   f0102ec1 <_paddr>
	e->env_pgdir = 0;
f0103527:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f010352e:	e8 2e fa ff ff       	call   f0102f61 <pa2page>
f0103533:	89 04 24             	mov    %eax,(%esp)
f0103536:	e8 56 e3 ff ff       	call   f0101891 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010353b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103542:	a1 2c 22 1a f0       	mov    0xf01a222c,%eax
f0103547:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010354a:	89 3d 2c 22 1a f0    	mov    %edi,0xf01a222c
}
f0103550:	83 c4 2c             	add    $0x2c,%esp
f0103553:	5b                   	pop    %ebx
f0103554:	5e                   	pop    %esi
f0103555:	5f                   	pop    %edi
f0103556:	5d                   	pop    %ebp
f0103557:	c3                   	ret    

f0103558 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103558:	55                   	push   %ebp
f0103559:	89 e5                	mov    %esp,%ebp
f010355b:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f010355e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103561:	89 04 24             	mov    %eax,(%esp)
f0103564:	e8 b9 fe ff ff       	call   f0103422 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103569:	c7 04 24 ac 60 10 f0 	movl   $0xf01060ac,(%esp)
f0103570:	e8 7d 01 00 00       	call   f01036f2 <cprintf>
	while (1)
		monitor(NULL);
f0103575:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010357c:	e8 d3 d4 ff ff       	call   f0100a54 <monitor>
f0103581:	eb f2                	jmp    f0103575 <env_destroy+0x1d>

f0103583 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103583:	55                   	push   %ebp
f0103584:	89 e5                	mov    %esp,%ebp
f0103586:	83 ec 18             	sub    $0x18,%esp
	asm volatile("\tmovl %0,%%esp\n"
f0103589:	8b 65 08             	mov    0x8(%ebp),%esp
f010358c:	61                   	popa   
f010358d:	07                   	pop    %es
f010358e:	1f                   	pop    %ds
f010358f:	83 c4 08             	add    $0x8,%esp
f0103592:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f0103593:	c7 44 24 08 97 61 10 	movl   $0xf0106197,0x8(%esp)
f010359a:	f0 
f010359b:	c7 44 24 04 ea 01 00 	movl   $0x1ea,0x4(%esp)
f01035a2:	00 
f01035a3:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f01035aa:	e8 17 cb ff ff       	call   f01000c6 <_panic>

f01035af <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035af:	55                   	push   %ebp
f01035b0:	89 e5                	mov    %esp,%ebp
f01035b2:	83 ec 18             	sub    $0x18,%esp
f01035b5:	8b 55 08             	mov    0x8(%ebp),%edx

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f01035b8:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f01035bd:	85 c0                	test   %eax,%eax
f01035bf:	74 0d                	je     f01035ce <env_run+0x1f>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f01035c1:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01035c5:	75 07                	jne    f01035ce <env_run+0x1f>
f01035c7:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si FREE no tiene nada, no tiene sentido
		//si DYING ????
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	assert(e->env_status != ENV_FREE);//DEBUG2
f01035ce:	8b 42 54             	mov    0x54(%edx),%eax
f01035d1:	85 c0                	test   %eax,%eax
f01035d3:	75 24                	jne    f01035f9 <env_run+0x4a>
f01035d5:	c7 44 24 0c a3 61 10 	movl   $0xf01061a3,0xc(%esp)
f01035dc:	f0 
f01035dd:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f01035e4:	f0 
f01035e5:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
f01035ec:	00 
f01035ed:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f01035f4:	e8 cd ca ff ff       	call   f01000c6 <_panic>
	assert(e->env_status == ENV_RUNNABLE);//DEBUG2
f01035f9:	83 f8 02             	cmp    $0x2,%eax
f01035fc:	74 24                	je     f0103622 <env_run+0x73>
f01035fe:	c7 44 24 0c bd 61 10 	movl   $0xf01061bd,0xc(%esp)
f0103605:	f0 
f0103606:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f010360d:	f0 
f010360e:	c7 44 24 04 14 02 00 	movl   $0x214,0x4(%esp)
f0103615:	00 
f0103616:	c7 04 24 e2 60 10 f0 	movl   $0xf01060e2,(%esp)
f010361d:	e8 a4 ca ff ff       	call   f01000c6 <_panic>
	curenv=e;
f0103622:	89 15 24 22 1a f0    	mov    %edx,0xf01a2224
	curenv->env_status = ENV_RUNNING;
f0103628:	c7 42 54 03 00 00 00 	movl   $0x3,0x54(%edx)
	curenv->env_runs++;
f010362f:	83 42 58 01          	addl   $0x1,0x58(%edx)
	lcr3(PADDR(curenv->env_pgdir));
f0103633:	8b 4a 5c             	mov    0x5c(%edx),%ecx
f0103636:	ba 18 02 00 00       	mov    $0x218,%edx
f010363b:	b8 e2 60 10 f0       	mov    $0xf01060e2,%eax
f0103640:	e8 7c f8 ff ff       	call   f0102ec1 <_paddr>
f0103645:	e8 00 f8 ff ff       	call   f0102e4a <lcr3>
	env_pop_tf(&(curenv->env_tf));
f010364a:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f010364f:	89 04 24             	mov    %eax,(%esp)
f0103652:	e8 2c ff ff ff       	call   f0103583 <env_pop_tf>

f0103657 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0103657:	55                   	push   %ebp
f0103658:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010365a:	89 c2                	mov    %eax,%edx
f010365c:	ec                   	in     (%dx),%al
	return data;
}
f010365d:	5d                   	pop    %ebp
f010365e:	c3                   	ret    

f010365f <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f010365f:	55                   	push   %ebp
f0103660:	89 e5                	mov    %esp,%ebp
f0103662:	89 c1                	mov    %eax,%ecx
f0103664:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103666:	89 ca                	mov    %ecx,%edx
f0103668:	ee                   	out    %al,(%dx)
}
f0103669:	5d                   	pop    %ebp
f010366a:	c3                   	ret    

f010366b <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010366b:	55                   	push   %ebp
f010366c:	89 e5                	mov    %esp,%ebp
f010366e:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f0103672:	b8 70 00 00 00       	mov    $0x70,%eax
f0103677:	e8 e3 ff ff ff       	call   f010365f <outb>
	return inb(IO_RTC+1);
f010367c:	b8 71 00 00 00       	mov    $0x71,%eax
f0103681:	e8 d1 ff ff ff       	call   f0103657 <inb>
f0103686:	0f b6 c0             	movzbl %al,%eax
}
f0103689:	5d                   	pop    %ebp
f010368a:	c3                   	ret    

f010368b <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010368b:	55                   	push   %ebp
f010368c:	89 e5                	mov    %esp,%ebp
f010368e:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
	outb(IO_RTC, reg);
f0103692:	b8 70 00 00 00       	mov    $0x70,%eax
f0103697:	e8 c3 ff ff ff       	call   f010365f <outb>
f010369c:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
	outb(IO_RTC+1, datum);
f01036a0:	b8 71 00 00 00       	mov    $0x71,%eax
f01036a5:	e8 b5 ff ff ff       	call   f010365f <outb>
}
f01036aa:	5d                   	pop    %ebp
f01036ab:	c3                   	ret    

f01036ac <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01036ac:	55                   	push   %ebp
f01036ad:	89 e5                	mov    %esp,%ebp
f01036af:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01036b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01036b5:	89 04 24             	mov    %eax,(%esp)
f01036b8:	e8 8b d0 ff ff       	call   f0100748 <cputchar>
	*cnt++;
}
f01036bd:	c9                   	leave  
f01036be:	c3                   	ret    

f01036bf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036bf:	55                   	push   %ebp
f01036c0:	89 e5                	mov    %esp,%ebp
f01036c2:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01036c5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036da:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036e1:	c7 04 24 ac 36 10 f0 	movl   $0xf01036ac,(%esp)
f01036e8:	e8 43 0e 00 00       	call   f0104530 <vprintfmt>
	return cnt;
}
f01036ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036f0:	c9                   	leave  
f01036f1:	c3                   	ret    

f01036f2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036f2:	55                   	push   %ebp
f01036f3:	89 e5                	mov    %esp,%ebp
f01036f5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036f8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01036fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103702:	89 04 24             	mov    %eax,(%esp)
f0103705:	e8 b5 ff ff ff       	call   f01036bf <vcprintf>
	va_end(ap);

	return cnt;
}
f010370a:	c9                   	leave  
f010370b:	c3                   	ret    

f010370c <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f010370c:	55                   	push   %ebp
f010370d:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f010370f:	0f 01 18             	lidtl  (%eax)
}
f0103712:	5d                   	pop    %ebp
f0103713:	c3                   	ret    

f0103714 <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f0103714:	55                   	push   %ebp
f0103715:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f0103717:	0f 00 d8             	ltr    %ax
}
f010371a:	5d                   	pop    %ebp
f010371b:	c3                   	ret    

f010371c <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f010371c:	55                   	push   %ebp
f010371d:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010371f:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f0103722:	5d                   	pop    %ebp
f0103723:	c3                   	ret    

f0103724 <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f0103724:	55                   	push   %ebp
f0103725:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103727:	9c                   	pushf  
f0103728:	58                   	pop    %eax
	return eflags;
}
f0103729:	5d                   	pop    %ebp
f010372a:	c3                   	ret    

f010372b <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f010372b:	55                   	push   %ebp
f010372c:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f010372e:	83 f8 13             	cmp    $0x13,%eax
f0103731:	77 09                	ja     f010373c <trapname+0x11>
		return excnames[trapno];
f0103733:	8b 04 85 80 65 10 f0 	mov    -0xfef9a80(,%eax,4),%eax
f010373a:	eb 10                	jmp    f010374c <trapname+0x21>
	if (trapno == T_SYSCALL)
f010373c:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
f010373f:	b8 db 61 10 f0       	mov    $0xf01061db,%eax
f0103744:	ba e7 61 10 f0       	mov    $0xf01061e7,%edx
f0103749:	0f 45 c2             	cmovne %edx,%eax
	return "(unknown trap)";
}
f010374c:	5d                   	pop    %ebp
f010374d:	c3                   	ret    

f010374e <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f010374e:	55                   	push   %ebp
f010374f:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103751:	c7 05 64 2a 1a f0 00 	movl   $0xf0000000,0xf01a2a64
f0103758:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010375b:	66 c7 05 68 2a 1a f0 	movw   $0x10,0xf01a2a68
f0103762:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0103764:	66 c7 05 48 03 11 f0 	movw   $0x67,0xf0110348
f010376b:	67 00 
f010376d:	b8 60 2a 1a f0       	mov    $0xf01a2a60,%eax
f0103772:	66 a3 4a 03 11 f0    	mov    %ax,0xf011034a
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f0103778:	89 c2                	mov    %eax,%edx
f010377a:	c1 ea 10             	shr    $0x10,%edx
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f010377d:	88 15 4c 03 11 f0    	mov    %dl,0xf011034c
f0103783:	c6 05 4e 03 11 f0 40 	movb   $0x40,0xf011034e
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
f010378a:	c1 e8 18             	shr    $0x18,%eax
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
	ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f010378d:	a2 4f 03 11 f0       	mov    %al,0xf011034f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103792:	c6 05 4d 03 11 f0 89 	movb   $0x89,0xf011034d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f0103799:	b8 28 00 00 00       	mov    $0x28,%eax
f010379e:	e8 71 ff ff ff       	call   f0103714 <ltr>

	// Load the IDT
	lidt(&idt_pd);
f01037a3:	b8 50 03 11 f0       	mov    $0xf0110350,%eax
f01037a8:	e8 5f ff ff ff       	call   f010370c <lidt>
}
f01037ad:	5d                   	pop    %ebp
f01037ae:	c3                   	ret    

f01037af <trap_init>:
void Trap_48();


void
trap_init(void)
{
f01037af:	55                   	push   %ebp
f01037b0:	89 e5                	mov    %esp,%ebp
f01037b2:	83 ec 18             	sub    $0x18,%esp
	cprintf("Se setean los gates \n");
f01037b5:	c7 04 24 f6 61 10 f0 	movl   $0xf01061f6,(%esp)
f01037bc:	e8 31 ff ff ff       	call   f01036f2 <cprintf>
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[0], 1, GD_KT, Trap_0, 0);
f01037c1:	b8 da 3e 10 f0       	mov    $0xf0103eda,%eax
f01037c6:	66 a3 40 22 1a f0    	mov    %ax,0xf01a2240
f01037cc:	66 c7 05 42 22 1a f0 	movw   $0x8,0xf01a2242
f01037d3:	08 00 
f01037d5:	c6 05 44 22 1a f0 00 	movb   $0x0,0xf01a2244
f01037dc:	c6 05 45 22 1a f0 8f 	movb   $0x8f,0xf01a2245
f01037e3:	c1 e8 10             	shr    $0x10,%eax
f01037e6:	66 a3 46 22 1a f0    	mov    %ax,0xf01a2246
	SETGATE(idt[1], 1, GD_KT, Trap_1, 0);
f01037ec:	b8 e0 3e 10 f0       	mov    $0xf0103ee0,%eax
f01037f1:	66 a3 48 22 1a f0    	mov    %ax,0xf01a2248
f01037f7:	66 c7 05 4a 22 1a f0 	movw   $0x8,0xf01a224a
f01037fe:	08 00 
f0103800:	c6 05 4c 22 1a f0 00 	movb   $0x0,0xf01a224c
f0103807:	c6 05 4d 22 1a f0 8f 	movb   $0x8f,0xf01a224d
f010380e:	c1 e8 10             	shr    $0x10,%eax
f0103811:	66 a3 4e 22 1a f0    	mov    %ax,0xf01a224e
	SETGATE(idt[2], 1, GD_KT, Trap_2, 0); 
f0103817:	b8 e6 3e 10 f0       	mov    $0xf0103ee6,%eax
f010381c:	66 a3 50 22 1a f0    	mov    %ax,0xf01a2250
f0103822:	66 c7 05 52 22 1a f0 	movw   $0x8,0xf01a2252
f0103829:	08 00 
f010382b:	c6 05 54 22 1a f0 00 	movb   $0x0,0xf01a2254
f0103832:	c6 05 55 22 1a f0 8f 	movb   $0x8f,0xf01a2255
f0103839:	c1 e8 10             	shr    $0x10,%eax
f010383c:	66 a3 56 22 1a f0    	mov    %ax,0xf01a2256
	SETGATE(idt[3], 0, GD_KT, Trap_3, 3);
f0103842:	b8 ec 3e 10 f0       	mov    $0xf0103eec,%eax
f0103847:	66 a3 58 22 1a f0    	mov    %ax,0xf01a2258
f010384d:	66 c7 05 5a 22 1a f0 	movw   $0x8,0xf01a225a
f0103854:	08 00 
f0103856:	c6 05 5c 22 1a f0 00 	movb   $0x0,0xf01a225c
f010385d:	c6 05 5d 22 1a f0 ee 	movb   $0xee,0xf01a225d
f0103864:	c1 e8 10             	shr    $0x10,%eax
f0103867:	66 a3 5e 22 1a f0    	mov    %ax,0xf01a225e
	SETGATE(idt[4], 1, GD_KT, Trap_4, 0);
f010386d:	b8 f2 3e 10 f0       	mov    $0xf0103ef2,%eax
f0103872:	66 a3 60 22 1a f0    	mov    %ax,0xf01a2260
f0103878:	66 c7 05 62 22 1a f0 	movw   $0x8,0xf01a2262
f010387f:	08 00 
f0103881:	c6 05 64 22 1a f0 00 	movb   $0x0,0xf01a2264
f0103888:	c6 05 65 22 1a f0 8f 	movb   $0x8f,0xf01a2265
f010388f:	c1 e8 10             	shr    $0x10,%eax
f0103892:	66 a3 66 22 1a f0    	mov    %ax,0xf01a2266
	SETGATE(idt[5], 1, GD_KT, Trap_5, 0);
f0103898:	b8 f8 3e 10 f0       	mov    $0xf0103ef8,%eax
f010389d:	66 a3 68 22 1a f0    	mov    %ax,0xf01a2268
f01038a3:	66 c7 05 6a 22 1a f0 	movw   $0x8,0xf01a226a
f01038aa:	08 00 
f01038ac:	c6 05 6c 22 1a f0 00 	movb   $0x0,0xf01a226c
f01038b3:	c6 05 6d 22 1a f0 8f 	movb   $0x8f,0xf01a226d
f01038ba:	c1 e8 10             	shr    $0x10,%eax
f01038bd:	66 a3 6e 22 1a f0    	mov    %ax,0xf01a226e
	SETGATE(idt[6], 1, GD_KT, Trap_6, 0);
f01038c3:	b8 fe 3e 10 f0       	mov    $0xf0103efe,%eax
f01038c8:	66 a3 70 22 1a f0    	mov    %ax,0xf01a2270
f01038ce:	66 c7 05 72 22 1a f0 	movw   $0x8,0xf01a2272
f01038d5:	08 00 
f01038d7:	c6 05 74 22 1a f0 00 	movb   $0x0,0xf01a2274
f01038de:	c6 05 75 22 1a f0 8f 	movb   $0x8f,0xf01a2275
f01038e5:	c1 e8 10             	shr    $0x10,%eax
f01038e8:	66 a3 76 22 1a f0    	mov    %ax,0xf01a2276
	SETGATE(idt[7], 1, GD_KT, Trap_7, 0);
f01038ee:	b8 04 3f 10 f0       	mov    $0xf0103f04,%eax
f01038f3:	66 a3 78 22 1a f0    	mov    %ax,0xf01a2278
f01038f9:	66 c7 05 7a 22 1a f0 	movw   $0x8,0xf01a227a
f0103900:	08 00 
f0103902:	c6 05 7c 22 1a f0 00 	movb   $0x0,0xf01a227c
f0103909:	c6 05 7d 22 1a f0 8f 	movb   $0x8f,0xf01a227d
f0103910:	c1 e8 10             	shr    $0x10,%eax
f0103913:	66 a3 7e 22 1a f0    	mov    %ax,0xf01a227e
	SETGATE(idt[8], 1, GD_KT, Trap_8, 0); 
f0103919:	b8 0a 3f 10 f0       	mov    $0xf0103f0a,%eax
f010391e:	66 a3 80 22 1a f0    	mov    %ax,0xf01a2280
f0103924:	66 c7 05 82 22 1a f0 	movw   $0x8,0xf01a2282
f010392b:	08 00 
f010392d:	c6 05 84 22 1a f0 00 	movb   $0x0,0xf01a2284
f0103934:	c6 05 85 22 1a f0 8f 	movb   $0x8f,0xf01a2285
f010393b:	c1 e8 10             	shr    $0x10,%eax
f010393e:	66 a3 86 22 1a f0    	mov    %ax,0xf01a2286
	SETGATE(idt[10], 1, GD_KT, Trap_10, 0); 
f0103944:	b8 0e 3f 10 f0       	mov    $0xf0103f0e,%eax
f0103949:	66 a3 90 22 1a f0    	mov    %ax,0xf01a2290
f010394f:	66 c7 05 92 22 1a f0 	movw   $0x8,0xf01a2292
f0103956:	08 00 
f0103958:	c6 05 94 22 1a f0 00 	movb   $0x0,0xf01a2294
f010395f:	c6 05 95 22 1a f0 8f 	movb   $0x8f,0xf01a2295
f0103966:	c1 e8 10             	shr    $0x10,%eax
f0103969:	66 a3 96 22 1a f0    	mov    %ax,0xf01a2296
	SETGATE(idt[11], 1, GD_KT, Trap_11, 0); 
f010396f:	b8 12 3f 10 f0       	mov    $0xf0103f12,%eax
f0103974:	66 a3 98 22 1a f0    	mov    %ax,0xf01a2298
f010397a:	66 c7 05 9a 22 1a f0 	movw   $0x8,0xf01a229a
f0103981:	08 00 
f0103983:	c6 05 9c 22 1a f0 00 	movb   $0x0,0xf01a229c
f010398a:	c6 05 9d 22 1a f0 8f 	movb   $0x8f,0xf01a229d
f0103991:	c1 e8 10             	shr    $0x10,%eax
f0103994:	66 a3 9e 22 1a f0    	mov    %ax,0xf01a229e
	SETGATE(idt[12], 1, GD_KT, Trap_12, 0); 
f010399a:	b8 16 3f 10 f0       	mov    $0xf0103f16,%eax
f010399f:	66 a3 a0 22 1a f0    	mov    %ax,0xf01a22a0
f01039a5:	66 c7 05 a2 22 1a f0 	movw   $0x8,0xf01a22a2
f01039ac:	08 00 
f01039ae:	c6 05 a4 22 1a f0 00 	movb   $0x0,0xf01a22a4
f01039b5:	c6 05 a5 22 1a f0 8f 	movb   $0x8f,0xf01a22a5
f01039bc:	c1 e8 10             	shr    $0x10,%eax
f01039bf:	66 a3 a6 22 1a f0    	mov    %ax,0xf01a22a6
	SETGATE(idt[13], 1, GD_KT, Trap_13, 0); 
f01039c5:	b8 1a 3f 10 f0       	mov    $0xf0103f1a,%eax
f01039ca:	66 a3 a8 22 1a f0    	mov    %ax,0xf01a22a8
f01039d0:	66 c7 05 aa 22 1a f0 	movw   $0x8,0xf01a22aa
f01039d7:	08 00 
f01039d9:	c6 05 ac 22 1a f0 00 	movb   $0x0,0xf01a22ac
f01039e0:	c6 05 ad 22 1a f0 8f 	movb   $0x8f,0xf01a22ad
f01039e7:	c1 e8 10             	shr    $0x10,%eax
f01039ea:	66 a3 ae 22 1a f0    	mov    %ax,0xf01a22ae
	SETGATE(idt[14], 1, GD_KT, Trap_14, 0); 
f01039f0:	b8 1e 3f 10 f0       	mov    $0xf0103f1e,%eax
f01039f5:	66 a3 b0 22 1a f0    	mov    %ax,0xf01a22b0
f01039fb:	66 c7 05 b2 22 1a f0 	movw   $0x8,0xf01a22b2
f0103a02:	08 00 
f0103a04:	c6 05 b4 22 1a f0 00 	movb   $0x0,0xf01a22b4
f0103a0b:	c6 05 b5 22 1a f0 8f 	movb   $0x8f,0xf01a22b5
f0103a12:	c1 e8 10             	shr    $0x10,%eax
f0103a15:	66 a3 b6 22 1a f0    	mov    %ax,0xf01a22b6
	SETGATE(idt[16], 1, GD_KT, Trap_16, 0);
f0103a1b:	b8 22 3f 10 f0       	mov    $0xf0103f22,%eax
f0103a20:	66 a3 c0 22 1a f0    	mov    %ax,0xf01a22c0
f0103a26:	66 c7 05 c2 22 1a f0 	movw   $0x8,0xf01a22c2
f0103a2d:	08 00 
f0103a2f:	c6 05 c4 22 1a f0 00 	movb   $0x0,0xf01a22c4
f0103a36:	c6 05 c5 22 1a f0 8f 	movb   $0x8f,0xf01a22c5
f0103a3d:	c1 e8 10             	shr    $0x10,%eax
f0103a40:	66 a3 c6 22 1a f0    	mov    %ax,0xf01a22c6
	SETGATE(idt[17], 1, GD_KT, Trap_17, 0); 
f0103a46:	b8 28 3f 10 f0       	mov    $0xf0103f28,%eax
f0103a4b:	66 a3 c8 22 1a f0    	mov    %ax,0xf01a22c8
f0103a51:	66 c7 05 ca 22 1a f0 	movw   $0x8,0xf01a22ca
f0103a58:	08 00 
f0103a5a:	c6 05 cc 22 1a f0 00 	movb   $0x0,0xf01a22cc
f0103a61:	c6 05 cd 22 1a f0 8f 	movb   $0x8f,0xf01a22cd
f0103a68:	c1 e8 10             	shr    $0x10,%eax
f0103a6b:	66 a3 ce 22 1a f0    	mov    %ax,0xf01a22ce
	SETGATE(idt[18], 1, GD_KT, Trap_18, 0); 
f0103a71:	b8 2c 3f 10 f0       	mov    $0xf0103f2c,%eax
f0103a76:	66 a3 d0 22 1a f0    	mov    %ax,0xf01a22d0
f0103a7c:	66 c7 05 d2 22 1a f0 	movw   $0x8,0xf01a22d2
f0103a83:	08 00 
f0103a85:	c6 05 d4 22 1a f0 00 	movb   $0x0,0xf01a22d4
f0103a8c:	c6 05 d5 22 1a f0 8f 	movb   $0x8f,0xf01a22d5
f0103a93:	c1 e8 10             	shr    $0x10,%eax
f0103a96:	66 a3 d6 22 1a f0    	mov    %ax,0xf01a22d6
	SETGATE(idt[19], 1, GD_KT, Trap_19, 0); 
f0103a9c:	b8 32 3f 10 f0       	mov    $0xf0103f32,%eax
f0103aa1:	66 a3 d8 22 1a f0    	mov    %ax,0xf01a22d8
f0103aa7:	66 c7 05 da 22 1a f0 	movw   $0x8,0xf01a22da
f0103aae:	08 00 
f0103ab0:	c6 05 dc 22 1a f0 00 	movb   $0x0,0xf01a22dc
f0103ab7:	c6 05 dd 22 1a f0 8f 	movb   $0x8f,0xf01a22dd
f0103abe:	c1 e8 10             	shr    $0x10,%eax
f0103ac1:	66 a3 de 22 1a f0    	mov    %ax,0xf01a22de
	SETGATE(idt[48], 0, GD_KT, Trap_48, 3);
f0103ac7:	b8 38 3f 10 f0       	mov    $0xf0103f38,%eax
f0103acc:	66 a3 c0 23 1a f0    	mov    %ax,0xf01a23c0
f0103ad2:	66 c7 05 c2 23 1a f0 	movw   $0x8,0xf01a23c2
f0103ad9:	08 00 
f0103adb:	c6 05 c4 23 1a f0 00 	movb   $0x0,0xf01a23c4
f0103ae2:	c6 05 c5 23 1a f0 ee 	movb   $0xee,0xf01a23c5
f0103ae9:	c1 e8 10             	shr    $0x10,%eax
f0103aec:	66 a3 c6 23 1a f0    	mov    %ax,0xf01a23c6

	cprintf("Se setearon los gates\n");
f0103af2:	c7 04 24 0c 62 10 f0 	movl   $0xf010620c,(%esp)
f0103af9:	e8 f4 fb ff ff       	call   f01036f2 <cprintf>

	// Per-CPU setup
	trap_init_percpu();
f0103afe:	e8 4b fc ff ff       	call   f010374e <trap_init_percpu>
}
f0103b03:	c9                   	leave  
f0103b04:	c3                   	ret    

f0103b05 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103b05:	55                   	push   %ebp
f0103b06:	89 e5                	mov    %esp,%ebp
f0103b08:	53                   	push   %ebx
f0103b09:	83 ec 14             	sub    $0x14,%esp
f0103b0c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103b0f:	8b 03                	mov    (%ebx),%eax
f0103b11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b15:	c7 04 24 23 62 10 f0 	movl   $0xf0106223,(%esp)
f0103b1c:	e8 d1 fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103b21:	8b 43 04             	mov    0x4(%ebx),%eax
f0103b24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b28:	c7 04 24 32 62 10 f0 	movl   $0xf0106232,(%esp)
f0103b2f:	e8 be fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103b34:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b3b:	c7 04 24 41 62 10 f0 	movl   $0xf0106241,(%esp)
f0103b42:	e8 ab fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103b47:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103b4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b4e:	c7 04 24 50 62 10 f0 	movl   $0xf0106250,(%esp)
f0103b55:	e8 98 fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103b5a:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b61:	c7 04 24 5f 62 10 f0 	movl   $0xf010625f,(%esp)
f0103b68:	e8 85 fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b6d:	8b 43 14             	mov    0x14(%ebx),%eax
f0103b70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b74:	c7 04 24 6e 62 10 f0 	movl   $0xf010626e,(%esp)
f0103b7b:	e8 72 fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b80:	8b 43 18             	mov    0x18(%ebx),%eax
f0103b83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b87:	c7 04 24 7d 62 10 f0 	movl   $0xf010627d,(%esp)
f0103b8e:	e8 5f fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b93:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103b96:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b9a:	c7 04 24 8c 62 10 f0 	movl   $0xf010628c,(%esp)
f0103ba1:	e8 4c fb ff ff       	call   f01036f2 <cprintf>
}
f0103ba6:	83 c4 14             	add    $0x14,%esp
f0103ba9:	5b                   	pop    %ebx
f0103baa:	5d                   	pop    %ebp
f0103bab:	c3                   	ret    

f0103bac <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103bac:	55                   	push   %ebp
f0103bad:	89 e5                	mov    %esp,%ebp
f0103baf:	56                   	push   %esi
f0103bb0:	53                   	push   %ebx
f0103bb1:	83 ec 10             	sub    $0x10,%esp
f0103bb4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103bb7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bbb:	c7 04 24 c0 63 10 f0 	movl   $0xf01063c0,(%esp)
f0103bc2:	e8 2b fb ff ff       	call   f01036f2 <cprintf>
	print_regs(&tf->tf_regs);
f0103bc7:	89 1c 24             	mov    %ebx,(%esp)
f0103bca:	e8 36 ff ff ff       	call   f0103b05 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103bcf:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103bd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bd7:	c7 04 24 c2 62 10 f0 	movl   $0xf01062c2,(%esp)
f0103bde:	e8 0f fb ff ff       	call   f01036f2 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103be3:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103be7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103beb:	c7 04 24 d5 62 10 f0 	movl   $0xf01062d5,(%esp)
f0103bf2:	e8 fb fa ff ff       	call   f01036f2 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bf7:	8b 73 28             	mov    0x28(%ebx),%esi
f0103bfa:	89 f0                	mov    %esi,%eax
f0103bfc:	e8 2a fb ff ff       	call   f010372b <trapname>
f0103c01:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c05:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103c09:	c7 04 24 e8 62 10 f0 	movl   $0xf01062e8,(%esp)
f0103c10:	e8 dd fa ff ff       	call   f01036f2 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103c15:	3b 1d 40 2a 1a f0    	cmp    0xf01a2a40,%ebx
f0103c1b:	75 1b                	jne    f0103c38 <print_trapframe+0x8c>
f0103c1d:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c21:	75 15                	jne    f0103c38 <print_trapframe+0x8c>
		cprintf("  cr2  0x%08x\n", rcr2());
f0103c23:	e8 f4 fa ff ff       	call   f010371c <rcr2>
f0103c28:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c2c:	c7 04 24 fa 62 10 f0 	movl   $0xf01062fa,(%esp)
f0103c33:	e8 ba fa ff ff       	call   f01036f2 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103c38:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c3b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c3f:	c7 04 24 09 63 10 f0 	movl   $0xf0106309,(%esp)
f0103c46:	e8 a7 fa ff ff       	call   f01036f2 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103c4b:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103c4f:	75 51                	jne    f0103ca2 <print_trapframe+0xf6>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f0103c51:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103c54:	89 c2                	mov    %eax,%edx
f0103c56:	83 e2 01             	and    $0x1,%edx
f0103c59:	ba 9b 62 10 f0       	mov    $0xf010629b,%edx
f0103c5e:	b9 a6 62 10 f0       	mov    $0xf01062a6,%ecx
f0103c63:	0f 45 ca             	cmovne %edx,%ecx
f0103c66:	89 c2                	mov    %eax,%edx
f0103c68:	83 e2 02             	and    $0x2,%edx
f0103c6b:	ba b2 62 10 f0       	mov    $0xf01062b2,%edx
f0103c70:	be b8 62 10 f0       	mov    $0xf01062b8,%esi
f0103c75:	0f 44 d6             	cmove  %esi,%edx
f0103c78:	83 e0 04             	and    $0x4,%eax
f0103c7b:	b8 bd 62 10 f0       	mov    $0xf01062bd,%eax
f0103c80:	be 8b 63 10 f0       	mov    $0xf010638b,%esi
f0103c85:	0f 44 c6             	cmove  %esi,%eax
f0103c88:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103c8c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c94:	c7 04 24 17 63 10 f0 	movl   $0xf0106317,(%esp)
f0103c9b:	e8 52 fa ff ff       	call   f01036f2 <cprintf>
f0103ca0:	eb 0c                	jmp    f0103cae <print_trapframe+0x102>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103ca2:	c7 04 24 0a 62 10 f0 	movl   $0xf010620a,(%esp)
f0103ca9:	e8 44 fa ff ff       	call   f01036f2 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103cae:	8b 43 30             	mov    0x30(%ebx),%eax
f0103cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cb5:	c7 04 24 26 63 10 f0 	movl   $0xf0106326,(%esp)
f0103cbc:	e8 31 fa ff ff       	call   f01036f2 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103cc1:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103cc5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cc9:	c7 04 24 35 63 10 f0 	movl   $0xf0106335,(%esp)
f0103cd0:	e8 1d fa ff ff       	call   f01036f2 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103cd5:	8b 43 38             	mov    0x38(%ebx),%eax
f0103cd8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cdc:	c7 04 24 48 63 10 f0 	movl   $0xf0106348,(%esp)
f0103ce3:	e8 0a fa ff ff       	call   f01036f2 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103ce8:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103cec:	74 27                	je     f0103d15 <print_trapframe+0x169>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103cee:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103cf1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cf5:	c7 04 24 57 63 10 f0 	movl   $0xf0106357,(%esp)
f0103cfc:	e8 f1 f9 ff ff       	call   f01036f2 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103d01:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103d05:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d09:	c7 04 24 66 63 10 f0 	movl   $0xf0106366,(%esp)
f0103d10:	e8 dd f9 ff ff       	call   f01036f2 <cprintf>
	}
}
f0103d15:	83 c4 10             	add    $0x10,%esp
f0103d18:	5b                   	pop    %ebx
f0103d19:	5e                   	pop    %esi
f0103d1a:	5d                   	pop    %ebp
f0103d1b:	c3                   	ret    

f0103d1c <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103d1c:	55                   	push   %ebp
f0103d1d:	89 e5                	mov    %esp,%ebp
f0103d1f:	53                   	push   %ebx
f0103d20:	83 ec 14             	sub    $0x14,%esp
f0103d23:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103d26:	e8 f1 f9 ff ff       	call   f010371c <rcr2>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103d2b:	8b 53 30             	mov    0x30(%ebx),%edx
f0103d2e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103d32:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d36:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103d3b:	8b 40 48             	mov    0x48(%eax),%eax
f0103d3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d42:	c7 04 24 1c 65 10 f0 	movl   $0xf010651c,(%esp)
f0103d49:	e8 a4 f9 ff ff       	call   f01036f2 <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f0103d4e:	89 1c 24             	mov    %ebx,(%esp)
f0103d51:	e8 56 fe ff ff       	call   f0103bac <print_trapframe>
	env_destroy(curenv);
f0103d56:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103d5b:	89 04 24             	mov    %eax,(%esp)
f0103d5e:	e8 f5 f7 ff ff       	call   f0103558 <env_destroy>
}
f0103d63:	83 c4 14             	add    $0x14,%esp
f0103d66:	5b                   	pop    %ebx
f0103d67:	5d                   	pop    %ebp
f0103d68:	c3                   	ret    

f0103d69 <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f0103d69:	55                   	push   %ebp
f0103d6a:	89 e5                	mov    %esp,%ebp
f0103d6c:	53                   	push   %ebx
f0103d6d:	83 ec 24             	sub    $0x24,%esp
f0103d70:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno == 3){
f0103d72:	83 78 28 03          	cmpl   $0x3,0x28(%eax)
f0103d76:	75 08                	jne    f0103d80 <trap_dispatch+0x17>
		monitor(tf);
f0103d78:	89 04 24             	mov    %eax,(%esp)
f0103d7b:	e8 d4 cc ff ff       	call   f0100a54 <monitor>
	}
	if(tf->tf_trapno == 14){
f0103d80:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103d84:	75 08                	jne    f0103d8e <trap_dispatch+0x25>
		page_fault_handler(tf);
f0103d86:	89 1c 24             	mov    %ebx,(%esp)
f0103d89:	e8 8e ff ff ff       	call   f0103d1c <page_fault_handler>
	}
	if(tf->tf_trapno == 48){
f0103d8e:	83 7b 28 30          	cmpl   $0x30,0x28(%ebx)
f0103d92:	75 2d                	jne    f0103dc1 <trap_dispatch+0x58>
		uint32_t resultado = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f0103d94:	8b 43 04             	mov    0x4(%ebx),%eax
f0103d97:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103d9b:	8b 03                	mov    (%ebx),%eax
f0103d9d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103da1:	8b 43 10             	mov    0x10(%ebx),%eax
f0103da4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103da8:	8b 43 18             	mov    0x18(%ebx),%eax
f0103dab:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103daf:	8b 43 14             	mov    0x14(%ebx),%eax
f0103db2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103db6:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103db9:	89 04 24             	mov    %eax,(%esp)
f0103dbc:	e8 34 02 00 00       	call   f0103ff5 <syscall>
			:"%eax");*/
	}


	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103dc1:	89 1c 24             	mov    %ebx,(%esp)
f0103dc4:	e8 e3 fd ff ff       	call   f0103bac <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103dc9:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103dce:	75 1c                	jne    f0103dec <trap_dispatch+0x83>
		panic("unhandled trap in kernel");
f0103dd0:	c7 44 24 08 79 63 10 	movl   $0xf0106379,0x8(%esp)
f0103dd7:	f0 
f0103dd8:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0103ddf:	00 
f0103de0:	c7 04 24 92 63 10 f0 	movl   $0xf0106392,(%esp)
f0103de7:	e8 da c2 ff ff       	call   f01000c6 <_panic>
	else {
		env_destroy(curenv);
f0103dec:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103df1:	89 04 24             	mov    %eax,(%esp)
f0103df4:	e8 5f f7 ff ff       	call   f0103558 <env_destroy>
		return;
	}
}
f0103df9:	83 c4 24             	add    $0x24,%esp
f0103dfc:	5b                   	pop    %ebx
f0103dfd:	5d                   	pop    %ebp
f0103dfe:	c3                   	ret    

f0103dff <trap>:

void
trap(struct Trapframe *tf)
{
f0103dff:	55                   	push   %ebp
f0103e00:	89 e5                	mov    %esp,%ebp
f0103e02:	57                   	push   %edi
f0103e03:	56                   	push   %esi
f0103e04:	83 ec 10             	sub    $0x10,%esp
f0103e07:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103e0a:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103e0b:	e8 14 f9 ff ff       	call   f0103724 <read_eflags>
f0103e10:	f6 c4 02             	test   $0x2,%ah
f0103e13:	74 24                	je     f0103e39 <trap+0x3a>
f0103e15:	c7 44 24 0c 9e 63 10 	movl   $0xf010639e,0xc(%esp)
f0103e1c:	f0 
f0103e1d:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0103e24:	f0 
f0103e25:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
f0103e2c:	00 
f0103e2d:	c7 04 24 92 63 10 f0 	movl   $0xf0106392,(%esp)
f0103e34:	e8 8d c2 ff ff       	call   f01000c6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103e39:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103e3d:	c7 04 24 b7 63 10 f0 	movl   $0xf01063b7,(%esp)
f0103e44:	e8 a9 f8 ff ff       	call   f01036f2 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103e49:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103e4d:	83 e0 03             	and    $0x3,%eax
f0103e50:	66 83 f8 03          	cmp    $0x3,%ax
f0103e54:	75 3c                	jne    f0103e92 <trap+0x93>
		// Trapped from user mode.
		assert(curenv);
f0103e56:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103e5b:	85 c0                	test   %eax,%eax
f0103e5d:	75 24                	jne    f0103e83 <trap+0x84>
f0103e5f:	c7 44 24 0c d2 63 10 	movl   $0xf01063d2,0xc(%esp)
f0103e66:	f0 
f0103e67:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0103e6e:	f0 
f0103e6f:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
f0103e76:	00 
f0103e77:	c7 04 24 92 63 10 f0 	movl   $0xf0106392,(%esp)
f0103e7e:	e8 43 c2 ff ff       	call   f01000c6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103e83:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103e88:	89 c7                	mov    %eax,%edi
f0103e8a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103e8c:	8b 35 24 22 1a f0    	mov    0xf01a2224,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103e92:	89 35 40 2a 1a f0    	mov    %esi,0xf01a2a40

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103e98:	89 f0                	mov    %esi,%eax
f0103e9a:	e8 ca fe ff ff       	call   f0103d69 <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103e9f:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103ea4:	85 c0                	test   %eax,%eax
f0103ea6:	74 06                	je     f0103eae <trap+0xaf>
f0103ea8:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103eac:	74 24                	je     f0103ed2 <trap+0xd3>
f0103eae:	c7 44 24 0c 40 65 10 	movl   $0xf0106540,0xc(%esp)
f0103eb5:	f0 
f0103eb6:	c7 44 24 08 9a 5d 10 	movl   $0xf0105d9a,0x8(%esp)
f0103ebd:	f0 
f0103ebe:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
f0103ec5:	00 
f0103ec6:	c7 04 24 92 63 10 f0 	movl   $0xf0106392,(%esp)
f0103ecd:	e8 f4 c1 ff ff       	call   f01000c6 <_panic>
	env_run(curenv);
f0103ed2:	89 04 24             	mov    %eax,(%esp)
f0103ed5:	e8 d5 f6 ff ff       	call   f01035af <env_run>

f0103eda <Trap_0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(Trap_0, T_DIVIDE)
f0103eda:	6a 00                	push   $0x0
f0103edc:	6a 00                	push   $0x0
f0103ede:	eb 5e                	jmp    f0103f3e <_alltraps>

f0103ee0 <Trap_1>:
TRAPHANDLER_NOEC(Trap_1, T_DEBUG)
f0103ee0:	6a 00                	push   $0x0
f0103ee2:	6a 01                	push   $0x1
f0103ee4:	eb 58                	jmp    f0103f3e <_alltraps>

f0103ee6 <Trap_2>:
TRAPHANDLER_NOEC(Trap_2, T_NMI)
f0103ee6:	6a 00                	push   $0x0
f0103ee8:	6a 02                	push   $0x2
f0103eea:	eb 52                	jmp    f0103f3e <_alltraps>

f0103eec <Trap_3>:
TRAPHANDLER_NOEC(Trap_3, T_BRKPT)
f0103eec:	6a 00                	push   $0x0
f0103eee:	6a 03                	push   $0x3
f0103ef0:	eb 4c                	jmp    f0103f3e <_alltraps>

f0103ef2 <Trap_4>:
TRAPHANDLER_NOEC(Trap_4, T_OFLOW)
f0103ef2:	6a 00                	push   $0x0
f0103ef4:	6a 04                	push   $0x4
f0103ef6:	eb 46                	jmp    f0103f3e <_alltraps>

f0103ef8 <Trap_5>:
TRAPHANDLER_NOEC(Trap_5, T_BOUND)
f0103ef8:	6a 00                	push   $0x0
f0103efa:	6a 05                	push   $0x5
f0103efc:	eb 40                	jmp    f0103f3e <_alltraps>

f0103efe <Trap_6>:
TRAPHANDLER_NOEC(Trap_6, T_ILLOP)
f0103efe:	6a 00                	push   $0x0
f0103f00:	6a 06                	push   $0x6
f0103f02:	eb 3a                	jmp    f0103f3e <_alltraps>

f0103f04 <Trap_7>:
TRAPHANDLER_NOEC(Trap_7, T_DEVICE)
f0103f04:	6a 00                	push   $0x0
f0103f06:	6a 07                	push   $0x7
f0103f08:	eb 34                	jmp    f0103f3e <_alltraps>

f0103f0a <Trap_8>:
TRAPHANDLER(Trap_8, T_DBLFLT)
f0103f0a:	6a 08                	push   $0x8
f0103f0c:	eb 30                	jmp    f0103f3e <_alltraps>

f0103f0e <Trap_10>:
TRAPHANDLER(Trap_10, T_TSS)
f0103f0e:	6a 0a                	push   $0xa
f0103f10:	eb 2c                	jmp    f0103f3e <_alltraps>

f0103f12 <Trap_11>:
TRAPHANDLER(Trap_11, T_SEGNP)
f0103f12:	6a 0b                	push   $0xb
f0103f14:	eb 28                	jmp    f0103f3e <_alltraps>

f0103f16 <Trap_12>:
TRAPHANDLER(Trap_12, T_STACK)
f0103f16:	6a 0c                	push   $0xc
f0103f18:	eb 24                	jmp    f0103f3e <_alltraps>

f0103f1a <Trap_13>:
TRAPHANDLER(Trap_13, T_GPFLT)
f0103f1a:	6a 0d                	push   $0xd
f0103f1c:	eb 20                	jmp    f0103f3e <_alltraps>

f0103f1e <Trap_14>:
TRAPHANDLER(Trap_14, T_PGFLT)
f0103f1e:	6a 0e                	push   $0xe
f0103f20:	eb 1c                	jmp    f0103f3e <_alltraps>

f0103f22 <Trap_16>:
TRAPHANDLER_NOEC(Trap_16, T_FPERR)
f0103f22:	6a 00                	push   $0x0
f0103f24:	6a 10                	push   $0x10
f0103f26:	eb 16                	jmp    f0103f3e <_alltraps>

f0103f28 <Trap_17>:
TRAPHANDLER(Trap_17, T_ALIGN)
f0103f28:	6a 11                	push   $0x11
f0103f2a:	eb 12                	jmp    f0103f3e <_alltraps>

f0103f2c <Trap_18>:
TRAPHANDLER_NOEC(Trap_18, T_MCHK)
f0103f2c:	6a 00                	push   $0x0
f0103f2e:	6a 12                	push   $0x12
f0103f30:	eb 0c                	jmp    f0103f3e <_alltraps>

f0103f32 <Trap_19>:
TRAPHANDLER_NOEC(Trap_19, T_SIMDERR)
f0103f32:	6a 00                	push   $0x0
f0103f34:	6a 13                	push   $0x13
f0103f36:	eb 06                	jmp    f0103f3e <_alltraps>

f0103f38 <Trap_48>:
TRAPHANDLER_NOEC(Trap_48, T_SYSCALL)
f0103f38:	6a 00                	push   $0x0
f0103f3a:	6a 30                	push   $0x30
f0103f3c:	eb 00                	jmp    f0103f3e <_alltraps>

f0103f3e <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f0103f3e:	1e                   	push   %ds
    pushl %es
f0103f3f:	06                   	push   %es
	pushal
f0103f40:	60                   	pusha  

	movw $GD_KD, %ax
f0103f41:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103f45:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f0103f47:	8e c0                	mov    %eax,%es

    pushl %esp
f0103f49:	54                   	push   %esp
    call trap	
f0103f4a:	e8 b0 fe ff ff       	call   f0103dff <trap>
f0103f4f:	90                   	nop

f0103f50 <sys_getenvid>:
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
f0103f50:	55                   	push   %ebp
f0103f51:	89 e5                	mov    %esp,%ebp
	return curenv->env_id;
f0103f53:	a1 24 22 1a f0       	mov    0xf01a2224,%eax
f0103f58:	8b 40 48             	mov    0x48(%eax),%eax
}
f0103f5b:	5d                   	pop    %ebp
f0103f5c:	c3                   	ret    

f0103f5d <sys_cputs>:
// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
f0103f5d:	55                   	push   %ebp
f0103f5e:	89 e5                	mov    %esp,%ebp
f0103f60:	83 ec 18             	sub    $0x18,%esp
	// Destroy the environment if not.

	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103f63:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f67:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103f6b:	c7 04 24 d0 65 10 f0 	movl   $0xf01065d0,(%esp)
f0103f72:	e8 7b f7 ff ff       	call   f01036f2 <cprintf>
}
f0103f77:	c9                   	leave  
f0103f78:	c3                   	ret    

f0103f79 <sys_cgetc>:

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
f0103f79:	55                   	push   %ebp
f0103f7a:	89 e5                	mov    %esp,%ebp
f0103f7c:	83 ec 08             	sub    $0x8,%esp
	return cons_getc();
f0103f7f:	e8 53 c7 ff ff       	call   f01006d7 <cons_getc>
}
f0103f84:	c9                   	leave  
f0103f85:	c3                   	ret    

f0103f86 <sys_env_destroy>:
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
f0103f86:	55                   	push   %ebp
f0103f87:	89 e5                	mov    %esp,%ebp
f0103f89:	83 ec 28             	sub    $0x28,%esp
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103f8c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103f93:	00 
f0103f94:	8d 55 f4             	lea    -0xc(%ebp),%edx
f0103f97:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103f9b:	89 04 24             	mov    %eax,(%esp)
f0103f9e:	e8 48 f2 ff ff       	call   f01031eb <envid2env>
f0103fa3:	85 c0                	test   %eax,%eax
f0103fa5:	78 4c                	js     f0103ff3 <sys_env_destroy+0x6d>
		return r;
	if (e == curenv)
f0103fa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103faa:	8b 15 24 22 1a f0    	mov    0xf01a2224,%edx
f0103fb0:	39 d0                	cmp    %edx,%eax
f0103fb2:	75 15                	jne    f0103fc9 <sys_env_destroy+0x43>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103fb4:	8b 40 48             	mov    0x48(%eax),%eax
f0103fb7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fbb:	c7 04 24 d5 65 10 f0 	movl   $0xf01065d5,(%esp)
f0103fc2:	e8 2b f7 ff ff       	call   f01036f2 <cprintf>
f0103fc7:	eb 1a                	jmp    f0103fe3 <sys_env_destroy+0x5d>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103fc9:	8b 40 48             	mov    0x48(%eax),%eax
f0103fcc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fd0:	8b 42 48             	mov    0x48(%edx),%eax
f0103fd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fd7:	c7 04 24 f0 65 10 f0 	movl   $0xf01065f0,(%esp)
f0103fde:	e8 0f f7 ff ff       	call   f01036f2 <cprintf>
	env_destroy(e);
f0103fe3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103fe6:	89 04 24             	mov    %eax,(%esp)
f0103fe9:	e8 6a f5 ff ff       	call   f0103558 <env_destroy>
	return 0;
f0103fee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ff3:	c9                   	leave  
f0103ff4:	c3                   	ret    

f0103ff5 <syscall>:

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103ff5:	55                   	push   %ebp
f0103ff6:	89 e5                	mov    %esp,%ebp
f0103ff8:	83 ec 08             	sub    $0x8,%esp
f0103ffb:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0103ffe:	83 f8 01             	cmp    $0x1,%eax
f0104001:	74 1c                	je     f010401f <syscall+0x2a>
f0104003:	83 f8 01             	cmp    $0x1,%eax
f0104006:	72 0c                	jb     f0104014 <syscall+0x1f>
f0104008:	83 f8 02             	cmp    $0x2,%eax
f010400b:	74 19                	je     f0104026 <syscall+0x31>
f010400d:	83 f8 03             	cmp    $0x3,%eax
f0104010:	74 20                	je     f0104032 <syscall+0x3d>
f0104012:	eb 28                	jmp    f010403c <syscall+0x47>
	case SYS_cputs:
		sys_cputs((char *)a1, a2);
f0104014:	8b 55 10             	mov    0x10(%ebp),%edx
f0104017:	8b 45 0c             	mov    0xc(%ebp),%eax
f010401a:	e8 3e ff ff ff       	call   f0103f5d <sys_cputs>
	case SYS_cgetc:
		return sys_cgetc();
f010401f:	e8 55 ff ff ff       	call   f0103f79 <sys_cgetc>
f0104024:	eb 1b                	jmp    f0104041 <syscall+0x4c>
	case SYS_getenvid:
		return sys_getenvid();
f0104026:	e8 25 ff ff ff       	call   f0103f50 <sys_getenvid>
f010402b:	90                   	nop
f010402c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104030:	eb 0f                	jmp    f0104041 <syscall+0x4c>
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104032:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104035:	e8 4c ff ff ff       	call   f0103f86 <sys_env_destroy>
f010403a:	eb 05                	jmp    f0104041 <syscall+0x4c>
	default:
		return -E_INVAL;
f010403c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f0104041:	c9                   	leave  
f0104042:	c3                   	ret    

f0104043 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f0104043:	55                   	push   %ebp
f0104044:	89 e5                	mov    %esp,%ebp
f0104046:	57                   	push   %edi
f0104047:	56                   	push   %esi
f0104048:	53                   	push   %ebx
f0104049:	83 ec 14             	sub    $0x14,%esp
f010404c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010404f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104052:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104055:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104058:	8b 1a                	mov    (%edx),%ebx
f010405a:	8b 01                	mov    (%ecx),%eax
f010405c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010405f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104066:	e9 88 00 00 00       	jmp    f01040f3 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010406b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010406e:	01 d8                	add    %ebx,%eax
f0104070:	89 c7                	mov    %eax,%edi
f0104072:	c1 ef 1f             	shr    $0x1f,%edi
f0104075:	01 c7                	add    %eax,%edi
f0104077:	d1 ff                	sar    %edi
f0104079:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010407c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010407f:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104082:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104084:	eb 03                	jmp    f0104089 <stab_binsearch+0x46>
			m--;
f0104086:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104089:	39 c3                	cmp    %eax,%ebx
f010408b:	7f 1f                	jg     f01040ac <stab_binsearch+0x69>
f010408d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104091:	83 ea 0c             	sub    $0xc,%edx
f0104094:	39 f1                	cmp    %esi,%ecx
f0104096:	75 ee                	jne    f0104086 <stab_binsearch+0x43>
f0104098:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010409b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010409e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01040a1:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01040a5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040a8:	76 18                	jbe    f01040c2 <stab_binsearch+0x7f>
f01040aa:	eb 05                	jmp    f01040b1 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f01040ac:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f01040af:	eb 42                	jmp    f01040f3 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01040b1:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01040b4:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01040b6:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040b9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01040c0:	eb 31                	jmp    f01040f3 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01040c2:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01040c5:	73 17                	jae    f01040de <stab_binsearch+0x9b>
			*region_right = m - 1;
f01040c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01040ca:	83 e8 01             	sub    $0x1,%eax
f01040cd:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01040d0:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01040d3:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040d5:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01040dc:	eb 15                	jmp    f01040f3 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01040de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040e1:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01040e4:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f01040e6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01040ea:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040ec:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01040f3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01040f6:	0f 8e 6f ff ff ff    	jle    f010406b <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01040fc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104100:	75 0f                	jne    f0104111 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104102:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104105:	8b 00                	mov    (%eax),%eax
f0104107:	83 e8 01             	sub    $0x1,%eax
f010410a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010410d:	89 07                	mov    %eax,(%edi)
f010410f:	eb 2c                	jmp    f010413d <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104111:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104114:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104116:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104119:	8b 0f                	mov    (%edi),%ecx
f010411b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010411e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104121:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104124:	eb 03                	jmp    f0104129 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104126:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104129:	39 c8                	cmp    %ecx,%eax
f010412b:	7e 0b                	jle    f0104138 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010412d:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104131:	83 ea 0c             	sub    $0xc,%edx
f0104134:	39 f3                	cmp    %esi,%ebx
f0104136:	75 ee                	jne    f0104126 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104138:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010413b:	89 07                	mov    %eax,(%edi)
	}
}
f010413d:	83 c4 14             	add    $0x14,%esp
f0104140:	5b                   	pop    %ebx
f0104141:	5e                   	pop    %esi
f0104142:	5f                   	pop    %edi
f0104143:	5d                   	pop    %ebp
f0104144:	c3                   	ret    

f0104145 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104145:	55                   	push   %ebp
f0104146:	89 e5                	mov    %esp,%ebp
f0104148:	57                   	push   %edi
f0104149:	56                   	push   %esi
f010414a:	53                   	push   %ebx
f010414b:	83 ec 4c             	sub    $0x4c,%esp
f010414e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104151:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104154:	c7 07 08 66 10 f0    	movl   $0xf0106608,(%edi)
	info->eip_line = 0;
f010415a:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104161:	c7 47 08 08 66 10 f0 	movl   $0xf0106608,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104168:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f010416f:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0104172:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104179:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010417f:	77 21                	ja     f01041a2 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0104181:	a1 00 00 20 00       	mov    0x200000,%eax
f0104186:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0104189:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010418e:	8b 35 08 00 20 00    	mov    0x200008,%esi
f0104194:	89 75 c0             	mov    %esi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104197:	8b 35 0c 00 20 00    	mov    0x20000c,%esi
f010419d:	89 75 bc             	mov    %esi,-0x44(%ebp)
f01041a0:	eb 1a                	jmp    f01041bc <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f01041a2:	c7 45 bc 21 68 10 f0 	movl   $0xf0106821,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f01041a9:	c7 45 c0 21 68 10 f0 	movl   $0xf0106821,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f01041b0:	b8 20 68 10 f0       	mov    $0xf0106820,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f01041b5:	c7 45 c4 20 68 10 f0 	movl   $0xf0106820,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01041bc:	8b 75 bc             	mov    -0x44(%ebp),%esi
f01041bf:	39 75 c0             	cmp    %esi,-0x40(%ebp)
f01041c2:	0f 83 9f 01 00 00    	jae    f0104367 <debuginfo_eip+0x222>
f01041c8:	80 7e ff 00          	cmpb   $0x0,-0x1(%esi)
f01041cc:	0f 85 9c 01 00 00    	jne    f010436e <debuginfo_eip+0x229>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01041d2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01041d9:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01041dc:	29 f0                	sub    %esi,%eax
f01041de:	c1 f8 02             	sar    $0x2,%eax
f01041e1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01041e7:	83 e8 01             	sub    $0x1,%eax
f01041ea:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01041ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01041f1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01041f8:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01041fb:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01041fe:	89 f0                	mov    %esi,%eax
f0104200:	e8 3e fe ff ff       	call   f0104043 <stab_binsearch>
	if (lfile == 0)
f0104205:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104208:	85 c0                	test   %eax,%eax
f010420a:	0f 84 65 01 00 00    	je     f0104375 <debuginfo_eip+0x230>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104210:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104213:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104216:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104219:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010421d:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104224:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104227:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010422a:	89 f0                	mov    %esi,%eax
f010422c:	e8 12 fe ff ff       	call   f0104043 <stab_binsearch>

	if (lfun <= rfun) {
f0104231:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104234:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0104237:	39 c8                	cmp    %ecx,%eax
f0104239:	7f 32                	jg     f010426d <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010423b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010423e:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104241:	8d 34 96             	lea    (%esi,%edx,4),%esi
f0104244:	8b 16                	mov    (%esi),%edx
f0104246:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104249:	8b 55 bc             	mov    -0x44(%ebp),%edx
f010424c:	2b 55 c0             	sub    -0x40(%ebp),%edx
f010424f:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104252:	73 09                	jae    f010425d <debuginfo_eip+0x118>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104254:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104257:	03 55 c0             	add    -0x40(%ebp),%edx
f010425a:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010425d:	8b 56 08             	mov    0x8(%esi),%edx
f0104260:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104263:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0104265:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104268:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010426b:	eb 0f                	jmp    f010427c <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010426d:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0104270:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104273:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104276:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104279:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010427c:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104283:	00 
f0104284:	8b 47 08             	mov    0x8(%edi),%eax
f0104287:	89 04 24             	mov    %eax,(%esp)
f010428a:	e8 ec 08 00 00       	call   f0104b7b <strfind>
f010428f:	2b 47 08             	sub    0x8(%edi),%eax
f0104292:	89 47 0c             	mov    %eax,0xc(%edi)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104295:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104299:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01042a0:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01042a3:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01042a6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01042a9:	e8 95 fd ff ff       	call   f0104043 <stab_binsearch>
	if (lline <= rline) {
f01042ae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01042b1:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01042b4:	7f 0e                	jg     f01042c4 <debuginfo_eip+0x17f>
		info->eip_line = stabs[lline].n_desc;
f01042b6:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01042b9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01042bc:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f01042c1:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f01042c4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042c7:	89 c6                	mov    %eax,%esi
f01042c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01042cc:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01042cf:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01042d2:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f01042d5:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01042d8:	89 f7                	mov    %esi,%edi
f01042da:	eb 06                	jmp    f01042e2 <debuginfo_eip+0x19d>
f01042dc:	83 e8 01             	sub    $0x1,%eax
f01042df:	83 ea 0c             	sub    $0xc,%edx
f01042e2:	89 c6                	mov    %eax,%esi
f01042e4:	39 c7                	cmp    %eax,%edi
f01042e6:	7f 3c                	jg     f0104324 <debuginfo_eip+0x1df>
f01042e8:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01042ec:	80 f9 84             	cmp    $0x84,%cl
f01042ef:	75 08                	jne    f01042f9 <debuginfo_eip+0x1b4>
f01042f1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01042f4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01042f7:	eb 11                	jmp    f010430a <debuginfo_eip+0x1c5>
f01042f9:	80 f9 64             	cmp    $0x64,%cl
f01042fc:	75 de                	jne    f01042dc <debuginfo_eip+0x197>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01042fe:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104302:	74 d8                	je     f01042dc <debuginfo_eip+0x197>
f0104304:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104307:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010430a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010430d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104310:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0104313:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104316:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104319:	39 d0                	cmp    %edx,%eax
f010431b:	73 0a                	jae    f0104327 <debuginfo_eip+0x1e2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010431d:	03 45 c0             	add    -0x40(%ebp),%eax
f0104320:	89 07                	mov    %eax,(%edi)
f0104322:	eb 03                	jmp    f0104327 <debuginfo_eip+0x1e2>
f0104324:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104327:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010432a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010432d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104332:	39 da                	cmp    %ebx,%edx
f0104334:	7d 4b                	jge    f0104381 <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
f0104336:	83 c2 01             	add    $0x1,%edx
f0104339:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010433c:	89 d0                	mov    %edx,%eax
f010433e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104341:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104344:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104347:	eb 04                	jmp    f010434d <debuginfo_eip+0x208>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104349:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010434d:	39 c3                	cmp    %eax,%ebx
f010434f:	7e 2b                	jle    f010437c <debuginfo_eip+0x237>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104351:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104355:	83 c0 01             	add    $0x1,%eax
f0104358:	83 c2 0c             	add    $0xc,%edx
f010435b:	80 f9 a0             	cmp    $0xa0,%cl
f010435e:	74 e9                	je     f0104349 <debuginfo_eip+0x204>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104360:	b8 00 00 00 00       	mov    $0x0,%eax
f0104365:	eb 1a                	jmp    f0104381 <debuginfo_eip+0x23c>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104367:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010436c:	eb 13                	jmp    f0104381 <debuginfo_eip+0x23c>
f010436e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104373:	eb 0c                	jmp    f0104381 <debuginfo_eip+0x23c>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104375:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010437a:	eb 05                	jmp    f0104381 <debuginfo_eip+0x23c>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010437c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104381:	83 c4 4c             	add    $0x4c,%esp
f0104384:	5b                   	pop    %ebx
f0104385:	5e                   	pop    %esi
f0104386:	5f                   	pop    %edi
f0104387:	5d                   	pop    %ebp
f0104388:	c3                   	ret    
f0104389:	66 90                	xchg   %ax,%ax
f010438b:	66 90                	xchg   %ax,%ax
f010438d:	66 90                	xchg   %ax,%ax
f010438f:	90                   	nop

f0104390 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104390:	55                   	push   %ebp
f0104391:	89 e5                	mov    %esp,%ebp
f0104393:	57                   	push   %edi
f0104394:	56                   	push   %esi
f0104395:	53                   	push   %ebx
f0104396:	83 ec 3c             	sub    $0x3c,%esp
f0104399:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010439c:	89 d7                	mov    %edx,%edi
f010439e:	8b 45 08             	mov    0x8(%ebp),%eax
f01043a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01043a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01043a7:	89 c3                	mov    %eax,%ebx
f01043a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01043ac:	8b 45 10             	mov    0x10(%ebp),%eax
f01043af:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01043b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01043b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01043ba:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01043bd:	39 d9                	cmp    %ebx,%ecx
f01043bf:	72 05                	jb     f01043c6 <printnum+0x36>
f01043c1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01043c4:	77 69                	ja     f010442f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01043c6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01043c9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01043cd:	83 ee 01             	sub    $0x1,%esi
f01043d0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01043d4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043d8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01043dc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01043e0:	89 c3                	mov    %eax,%ebx
f01043e2:	89 d6                	mov    %edx,%esi
f01043e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01043e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01043ea:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043ee:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043f5:	89 04 24             	mov    %eax,(%esp)
f01043f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01043fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ff:	e8 9c 09 00 00       	call   f0104da0 <__udivdi3>
f0104404:	89 d9                	mov    %ebx,%ecx
f0104406:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010440a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010440e:	89 04 24             	mov    %eax,(%esp)
f0104411:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104415:	89 fa                	mov    %edi,%edx
f0104417:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010441a:	e8 71 ff ff ff       	call   f0104390 <printnum>
f010441f:	eb 1b                	jmp    f010443c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104421:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104425:	8b 45 18             	mov    0x18(%ebp),%eax
f0104428:	89 04 24             	mov    %eax,(%esp)
f010442b:	ff d3                	call   *%ebx
f010442d:	eb 03                	jmp    f0104432 <printnum+0xa2>
f010442f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104432:	83 ee 01             	sub    $0x1,%esi
f0104435:	85 f6                	test   %esi,%esi
f0104437:	7f e8                	jg     f0104421 <printnum+0x91>
f0104439:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010443c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104440:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104444:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104447:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010444a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010444e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104452:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104455:	89 04 24             	mov    %eax,(%esp)
f0104458:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010445b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010445f:	e8 6c 0a 00 00       	call   f0104ed0 <__umoddi3>
f0104464:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104468:	0f be 80 12 66 10 f0 	movsbl -0xfef99ee(%eax),%eax
f010446f:	89 04 24             	mov    %eax,(%esp)
f0104472:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104475:	ff d0                	call   *%eax
}
f0104477:	83 c4 3c             	add    $0x3c,%esp
f010447a:	5b                   	pop    %ebx
f010447b:	5e                   	pop    %esi
f010447c:	5f                   	pop    %edi
f010447d:	5d                   	pop    %ebp
f010447e:	c3                   	ret    

f010447f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010447f:	55                   	push   %ebp
f0104480:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104482:	83 fa 01             	cmp    $0x1,%edx
f0104485:	7e 0e                	jle    f0104495 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104487:	8b 10                	mov    (%eax),%edx
f0104489:	8d 4a 08             	lea    0x8(%edx),%ecx
f010448c:	89 08                	mov    %ecx,(%eax)
f010448e:	8b 02                	mov    (%edx),%eax
f0104490:	8b 52 04             	mov    0x4(%edx),%edx
f0104493:	eb 22                	jmp    f01044b7 <getuint+0x38>
	else if (lflag)
f0104495:	85 d2                	test   %edx,%edx
f0104497:	74 10                	je     f01044a9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104499:	8b 10                	mov    (%eax),%edx
f010449b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010449e:	89 08                	mov    %ecx,(%eax)
f01044a0:	8b 02                	mov    (%edx),%eax
f01044a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01044a7:	eb 0e                	jmp    f01044b7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01044a9:	8b 10                	mov    (%eax),%edx
f01044ab:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044ae:	89 08                	mov    %ecx,(%eax)
f01044b0:	8b 02                	mov    (%edx),%eax
f01044b2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01044b7:	5d                   	pop    %ebp
f01044b8:	c3                   	ret    

f01044b9 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01044b9:	55                   	push   %ebp
f01044ba:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01044bc:	83 fa 01             	cmp    $0x1,%edx
f01044bf:	7e 0e                	jle    f01044cf <getint+0x16>
		return va_arg(*ap, long long);
f01044c1:	8b 10                	mov    (%eax),%edx
f01044c3:	8d 4a 08             	lea    0x8(%edx),%ecx
f01044c6:	89 08                	mov    %ecx,(%eax)
f01044c8:	8b 02                	mov    (%edx),%eax
f01044ca:	8b 52 04             	mov    0x4(%edx),%edx
f01044cd:	eb 1a                	jmp    f01044e9 <getint+0x30>
	else if (lflag)
f01044cf:	85 d2                	test   %edx,%edx
f01044d1:	74 0c                	je     f01044df <getint+0x26>
		return va_arg(*ap, long);
f01044d3:	8b 10                	mov    (%eax),%edx
f01044d5:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044d8:	89 08                	mov    %ecx,(%eax)
f01044da:	8b 02                	mov    (%edx),%eax
f01044dc:	99                   	cltd   
f01044dd:	eb 0a                	jmp    f01044e9 <getint+0x30>
	else
		return va_arg(*ap, int);
f01044df:	8b 10                	mov    (%eax),%edx
f01044e1:	8d 4a 04             	lea    0x4(%edx),%ecx
f01044e4:	89 08                	mov    %ecx,(%eax)
f01044e6:	8b 02                	mov    (%edx),%eax
f01044e8:	99                   	cltd   
}
f01044e9:	5d                   	pop    %ebp
f01044ea:	c3                   	ret    

f01044eb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01044eb:	55                   	push   %ebp
f01044ec:	89 e5                	mov    %esp,%ebp
f01044ee:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01044f1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01044f5:	8b 10                	mov    (%eax),%edx
f01044f7:	3b 50 04             	cmp    0x4(%eax),%edx
f01044fa:	73 0a                	jae    f0104506 <sprintputch+0x1b>
		*b->buf++ = ch;
f01044fc:	8d 4a 01             	lea    0x1(%edx),%ecx
f01044ff:	89 08                	mov    %ecx,(%eax)
f0104501:	8b 45 08             	mov    0x8(%ebp),%eax
f0104504:	88 02                	mov    %al,(%edx)
}
f0104506:	5d                   	pop    %ebp
f0104507:	c3                   	ret    

f0104508 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104508:	55                   	push   %ebp
f0104509:	89 e5                	mov    %esp,%ebp
f010450b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010450e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104511:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104515:	8b 45 10             	mov    0x10(%ebp),%eax
f0104518:	89 44 24 08          	mov    %eax,0x8(%esp)
f010451c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010451f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104523:	8b 45 08             	mov    0x8(%ebp),%eax
f0104526:	89 04 24             	mov    %eax,(%esp)
f0104529:	e8 02 00 00 00       	call   f0104530 <vprintfmt>
	va_end(ap);
}
f010452e:	c9                   	leave  
f010452f:	c3                   	ret    

f0104530 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104530:	55                   	push   %ebp
f0104531:	89 e5                	mov    %esp,%ebp
f0104533:	57                   	push   %edi
f0104534:	56                   	push   %esi
f0104535:	53                   	push   %ebx
f0104536:	83 ec 3c             	sub    $0x3c,%esp
f0104539:	8b 75 0c             	mov    0xc(%ebp),%esi
f010453c:	8b 7d 10             	mov    0x10(%ebp),%edi
f010453f:	eb 14                	jmp    f0104555 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104541:	85 c0                	test   %eax,%eax
f0104543:	0f 84 63 03 00 00    	je     f01048ac <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
f0104549:	89 74 24 04          	mov    %esi,0x4(%esp)
f010454d:	89 04 24             	mov    %eax,(%esp)
f0104550:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104553:	89 df                	mov    %ebx,%edi
f0104555:	8d 5f 01             	lea    0x1(%edi),%ebx
f0104558:	0f b6 07             	movzbl (%edi),%eax
f010455b:	83 f8 25             	cmp    $0x25,%eax
f010455e:	75 e1                	jne    f0104541 <vprintfmt+0x11>
f0104560:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104564:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010456b:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104572:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104579:	ba 00 00 00 00       	mov    $0x0,%edx
f010457e:	eb 1d                	jmp    f010459d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104580:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0104582:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104586:	eb 15                	jmp    f010459d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104588:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010458a:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010458e:	eb 0d                	jmp    f010459d <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104590:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104593:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104596:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010459d:	8d 7b 01             	lea    0x1(%ebx),%edi
f01045a0:	0f b6 0b             	movzbl (%ebx),%ecx
f01045a3:	0f b6 c1             	movzbl %cl,%eax
f01045a6:	83 e9 23             	sub    $0x23,%ecx
f01045a9:	80 f9 55             	cmp    $0x55,%cl
f01045ac:	0f 87 da 02 00 00    	ja     f010488c <vprintfmt+0x35c>
f01045b2:	0f b6 c9             	movzbl %cl,%ecx
f01045b5:	ff 24 8d 9c 66 10 f0 	jmp    *-0xfef9964(,%ecx,4)
f01045bc:	89 fb                	mov    %edi,%ebx
f01045be:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01045c3:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01045c6:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01045ca:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f01045cd:	8d 78 d0             	lea    -0x30(%eax),%edi
f01045d0:	83 ff 09             	cmp    $0x9,%edi
f01045d3:	77 36                	ja     f010460b <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01045d5:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01045d8:	eb e9                	jmp    f01045c3 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01045da:	8b 45 14             	mov    0x14(%ebp),%eax
f01045dd:	8d 48 04             	lea    0x4(%eax),%ecx
f01045e0:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01045e3:	8b 00                	mov    (%eax),%eax
f01045e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045e8:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01045ea:	eb 22                	jmp    f010460e <vprintfmt+0xde>
f01045ec:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01045ef:	85 c9                	test   %ecx,%ecx
f01045f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01045f6:	0f 49 c1             	cmovns %ecx,%eax
f01045f9:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01045fc:	89 fb                	mov    %edi,%ebx
f01045fe:	eb 9d                	jmp    f010459d <vprintfmt+0x6d>
f0104600:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104602:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104609:	eb 92                	jmp    f010459d <vprintfmt+0x6d>
f010460b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010460e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104612:	79 89                	jns    f010459d <vprintfmt+0x6d>
f0104614:	e9 77 ff ff ff       	jmp    f0104590 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104619:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010461c:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010461e:	e9 7a ff ff ff       	jmp    f010459d <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104623:	8b 45 14             	mov    0x14(%ebp),%eax
f0104626:	8d 50 04             	lea    0x4(%eax),%edx
f0104629:	89 55 14             	mov    %edx,0x14(%ebp)
f010462c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104630:	8b 00                	mov    (%eax),%eax
f0104632:	89 04 24             	mov    %eax,(%esp)
f0104635:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104638:	e9 18 ff ff ff       	jmp    f0104555 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010463d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104640:	8d 50 04             	lea    0x4(%eax),%edx
f0104643:	89 55 14             	mov    %edx,0x14(%ebp)
f0104646:	8b 00                	mov    (%eax),%eax
f0104648:	99                   	cltd   
f0104649:	31 d0                	xor    %edx,%eax
f010464b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010464d:	83 f8 06             	cmp    $0x6,%eax
f0104650:	7f 0b                	jg     f010465d <vprintfmt+0x12d>
f0104652:	8b 14 85 f4 67 10 f0 	mov    -0xfef980c(,%eax,4),%edx
f0104659:	85 d2                	test   %edx,%edx
f010465b:	75 20                	jne    f010467d <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010465d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104661:	c7 44 24 08 2a 66 10 	movl   $0xf010662a,0x8(%esp)
f0104668:	f0 
f0104669:	89 74 24 04          	mov    %esi,0x4(%esp)
f010466d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104670:	89 04 24             	mov    %eax,(%esp)
f0104673:	e8 90 fe ff ff       	call   f0104508 <printfmt>
f0104678:	e9 d8 fe ff ff       	jmp    f0104555 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010467d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104681:	c7 44 24 08 ac 5d 10 	movl   $0xf0105dac,0x8(%esp)
f0104688:	f0 
f0104689:	89 74 24 04          	mov    %esi,0x4(%esp)
f010468d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104690:	89 04 24             	mov    %eax,(%esp)
f0104693:	e8 70 fe ff ff       	call   f0104508 <printfmt>
f0104698:	e9 b8 fe ff ff       	jmp    f0104555 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010469d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01046a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01046a3:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01046a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01046a9:	8d 50 04             	lea    0x4(%eax),%edx
f01046ac:	89 55 14             	mov    %edx,0x14(%ebp)
f01046af:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01046b1:	85 db                	test   %ebx,%ebx
f01046b3:	b8 23 66 10 f0       	mov    $0xf0106623,%eax
f01046b8:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01046bb:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01046bf:	0f 84 97 00 00 00    	je     f010475c <vprintfmt+0x22c>
f01046c5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01046c9:	0f 8e 9b 00 00 00    	jle    f010476a <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01046cf:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01046d3:	89 1c 24             	mov    %ebx,(%esp)
f01046d6:	e8 4d 03 00 00       	call   f0104a28 <strnlen>
f01046db:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01046de:	29 c2                	sub    %eax,%edx
f01046e0:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01046e3:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01046e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01046ea:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01046ed:	89 d3                	mov    %edx,%ebx
f01046ef:	89 7d 10             	mov    %edi,0x10(%ebp)
f01046f2:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01046f5:	eb 0f                	jmp    f0104706 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01046f7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01046fb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01046fe:	89 04 24             	mov    %eax,(%esp)
f0104701:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104703:	83 eb 01             	sub    $0x1,%ebx
f0104706:	85 db                	test   %ebx,%ebx
f0104708:	7f ed                	jg     f01046f7 <vprintfmt+0x1c7>
f010470a:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010470d:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0104710:	85 d2                	test   %edx,%edx
f0104712:	b8 00 00 00 00       	mov    $0x0,%eax
f0104717:	0f 49 c2             	cmovns %edx,%eax
f010471a:	29 c2                	sub    %eax,%edx
f010471c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010471f:	89 d6                	mov    %edx,%esi
f0104721:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104724:	eb 50                	jmp    f0104776 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104726:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010472a:	74 1e                	je     f010474a <vprintfmt+0x21a>
f010472c:	0f be d2             	movsbl %dl,%edx
f010472f:	83 ea 20             	sub    $0x20,%edx
f0104732:	83 fa 5e             	cmp    $0x5e,%edx
f0104735:	76 13                	jbe    f010474a <vprintfmt+0x21a>
					putch('?', putdat);
f0104737:	8b 45 0c             	mov    0xc(%ebp),%eax
f010473a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010473e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104745:	ff 55 08             	call   *0x8(%ebp)
f0104748:	eb 0d                	jmp    f0104757 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f010474a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010474d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104751:	89 04 24             	mov    %eax,(%esp)
f0104754:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104757:	83 ee 01             	sub    $0x1,%esi
f010475a:	eb 1a                	jmp    f0104776 <vprintfmt+0x246>
f010475c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010475f:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104762:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104765:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104768:	eb 0c                	jmp    f0104776 <vprintfmt+0x246>
f010476a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010476d:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0104770:	89 7d 10             	mov    %edi,0x10(%ebp)
f0104773:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104776:	83 c3 01             	add    $0x1,%ebx
f0104779:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
f010477d:	0f be c2             	movsbl %dl,%eax
f0104780:	85 c0                	test   %eax,%eax
f0104782:	74 25                	je     f01047a9 <vprintfmt+0x279>
f0104784:	85 ff                	test   %edi,%edi
f0104786:	78 9e                	js     f0104726 <vprintfmt+0x1f6>
f0104788:	83 ef 01             	sub    $0x1,%edi
f010478b:	79 99                	jns    f0104726 <vprintfmt+0x1f6>
f010478d:	89 f3                	mov    %esi,%ebx
f010478f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104792:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104795:	eb 1a                	jmp    f01047b1 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104797:	89 74 24 04          	mov    %esi,0x4(%esp)
f010479b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01047a2:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01047a4:	83 eb 01             	sub    $0x1,%ebx
f01047a7:	eb 08                	jmp    f01047b1 <vprintfmt+0x281>
f01047a9:	89 f3                	mov    %esi,%ebx
f01047ab:	8b 7d 08             	mov    0x8(%ebp),%edi
f01047ae:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047b1:	85 db                	test   %ebx,%ebx
f01047b3:	7f e2                	jg     f0104797 <vprintfmt+0x267>
f01047b5:	89 7d 08             	mov    %edi,0x8(%ebp)
f01047b8:	8b 7d 10             	mov    0x10(%ebp),%edi
f01047bb:	e9 95 fd ff ff       	jmp    f0104555 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01047c0:	8d 45 14             	lea    0x14(%ebp),%eax
f01047c3:	e8 f1 fc ff ff       	call   f01044b9 <getint>
f01047c8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01047cb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01047ce:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01047d3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01047d7:	79 7b                	jns    f0104854 <vprintfmt+0x324>
				putch('-', putdat);
f01047d9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047dd:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01047e4:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01047e7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047ea:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01047ed:	f7 d8                	neg    %eax
f01047ef:	83 d2 00             	adc    $0x0,%edx
f01047f2:	f7 da                	neg    %edx
f01047f4:	eb 5e                	jmp    f0104854 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01047f6:	8d 45 14             	lea    0x14(%ebp),%eax
f01047f9:	e8 81 fc ff ff       	call   f010447f <getuint>
			base = 10;
f01047fe:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
f0104803:	eb 4f                	jmp    f0104854 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0104805:	8d 45 14             	lea    0x14(%ebp),%eax
f0104808:	e8 72 fc ff ff       	call   f010447f <getuint>
			base = 8;
f010480d:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
f0104812:	eb 40                	jmp    f0104854 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
f0104814:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104818:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010481f:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104822:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104826:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010482d:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104830:	8b 45 14             	mov    0x14(%ebp),%eax
f0104833:	8d 50 04             	lea    0x4(%eax),%edx
f0104836:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104839:	8b 00                	mov    (%eax),%eax
f010483b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104840:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
f0104845:	eb 0d                	jmp    f0104854 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104847:	8d 45 14             	lea    0x14(%ebp),%eax
f010484a:	e8 30 fc ff ff       	call   f010447f <getuint>
			base = 16;
f010484f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104854:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
f0104858:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010485c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010485f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104863:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104867:	89 04 24             	mov    %eax,(%esp)
f010486a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010486e:	89 f2                	mov    %esi,%edx
f0104870:	8b 45 08             	mov    0x8(%ebp),%eax
f0104873:	e8 18 fb ff ff       	call   f0104390 <printnum>
			break;
f0104878:	e9 d8 fc ff ff       	jmp    f0104555 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010487d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104881:	89 04 24             	mov    %eax,(%esp)
f0104884:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104887:	e9 c9 fc ff ff       	jmp    f0104555 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010488c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104890:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104897:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010489a:	89 df                	mov    %ebx,%edi
f010489c:	eb 03                	jmp    f01048a1 <vprintfmt+0x371>
f010489e:	83 ef 01             	sub    $0x1,%edi
f01048a1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01048a5:	75 f7                	jne    f010489e <vprintfmt+0x36e>
f01048a7:	e9 a9 fc ff ff       	jmp    f0104555 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01048ac:	83 c4 3c             	add    $0x3c,%esp
f01048af:	5b                   	pop    %ebx
f01048b0:	5e                   	pop    %esi
f01048b1:	5f                   	pop    %edi
f01048b2:	5d                   	pop    %ebp
f01048b3:	c3                   	ret    

f01048b4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01048b4:	55                   	push   %ebp
f01048b5:	89 e5                	mov    %esp,%ebp
f01048b7:	83 ec 28             	sub    $0x28,%esp
f01048ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01048bd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01048c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01048c3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01048c7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01048ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01048d1:	85 c0                	test   %eax,%eax
f01048d3:	74 30                	je     f0104905 <vsnprintf+0x51>
f01048d5:	85 d2                	test   %edx,%edx
f01048d7:	7e 2c                	jle    f0104905 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01048d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01048dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01048e0:	8b 45 10             	mov    0x10(%ebp),%eax
f01048e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01048e7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01048ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01048ee:	c7 04 24 eb 44 10 f0 	movl   $0xf01044eb,(%esp)
f01048f5:	e8 36 fc ff ff       	call   f0104530 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01048fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01048fd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104900:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104903:	eb 05                	jmp    f010490a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104905:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010490a:	c9                   	leave  
f010490b:	c3                   	ret    

f010490c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010490c:	55                   	push   %ebp
f010490d:	89 e5                	mov    %esp,%ebp
f010490f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104912:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104915:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104919:	8b 45 10             	mov    0x10(%ebp),%eax
f010491c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104920:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104923:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104927:	8b 45 08             	mov    0x8(%ebp),%eax
f010492a:	89 04 24             	mov    %eax,(%esp)
f010492d:	e8 82 ff ff ff       	call   f01048b4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104932:	c9                   	leave  
f0104933:	c3                   	ret    
f0104934:	66 90                	xchg   %ax,%ax
f0104936:	66 90                	xchg   %ax,%ax
f0104938:	66 90                	xchg   %ax,%ax
f010493a:	66 90                	xchg   %ax,%ax
f010493c:	66 90                	xchg   %ax,%ax
f010493e:	66 90                	xchg   %ax,%ax

f0104940 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104940:	55                   	push   %ebp
f0104941:	89 e5                	mov    %esp,%ebp
f0104943:	57                   	push   %edi
f0104944:	56                   	push   %esi
f0104945:	53                   	push   %ebx
f0104946:	83 ec 1c             	sub    $0x1c,%esp
f0104949:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010494c:	85 c0                	test   %eax,%eax
f010494e:	74 10                	je     f0104960 <readline+0x20>
		cprintf("%s", prompt);
f0104950:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104954:	c7 04 24 ac 5d 10 f0 	movl   $0xf0105dac,(%esp)
f010495b:	e8 92 ed ff ff       	call   f01036f2 <cprintf>

	i = 0;
	echoing = iscons(0);
f0104960:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104967:	e8 fd bd ff ff       	call   f0100769 <iscons>
f010496c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010496e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104973:	e8 e0 bd ff ff       	call   f0100758 <getchar>
f0104978:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010497a:	85 c0                	test   %eax,%eax
f010497c:	79 17                	jns    f0104995 <readline+0x55>
			cprintf("read error: %e\n", c);
f010497e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104982:	c7 04 24 10 68 10 f0 	movl   $0xf0106810,(%esp)
f0104989:	e8 64 ed ff ff       	call   f01036f2 <cprintf>
			return NULL;
f010498e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104993:	eb 6d                	jmp    f0104a02 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104995:	83 f8 7f             	cmp    $0x7f,%eax
f0104998:	74 05                	je     f010499f <readline+0x5f>
f010499a:	83 f8 08             	cmp    $0x8,%eax
f010499d:	75 19                	jne    f01049b8 <readline+0x78>
f010499f:	85 f6                	test   %esi,%esi
f01049a1:	7e 15                	jle    f01049b8 <readline+0x78>
			if (echoing)
f01049a3:	85 ff                	test   %edi,%edi
f01049a5:	74 0c                	je     f01049b3 <readline+0x73>
				cputchar('\b');
f01049a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01049ae:	e8 95 bd ff ff       	call   f0100748 <cputchar>
			i--;
f01049b3:	83 ee 01             	sub    $0x1,%esi
f01049b6:	eb bb                	jmp    f0104973 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01049b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01049be:	7f 1c                	jg     f01049dc <readline+0x9c>
f01049c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01049c3:	7e 17                	jle    f01049dc <readline+0x9c>
			if (echoing)
f01049c5:	85 ff                	test   %edi,%edi
f01049c7:	74 08                	je     f01049d1 <readline+0x91>
				cputchar(c);
f01049c9:	89 1c 24             	mov    %ebx,(%esp)
f01049cc:	e8 77 bd ff ff       	call   f0100748 <cputchar>
			buf[i++] = c;
f01049d1:	88 9e e0 2a 1a f0    	mov    %bl,-0xfe5d520(%esi)
f01049d7:	8d 76 01             	lea    0x1(%esi),%esi
f01049da:	eb 97                	jmp    f0104973 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01049dc:	83 fb 0d             	cmp    $0xd,%ebx
f01049df:	74 05                	je     f01049e6 <readline+0xa6>
f01049e1:	83 fb 0a             	cmp    $0xa,%ebx
f01049e4:	75 8d                	jne    f0104973 <readline+0x33>
			if (echoing)
f01049e6:	85 ff                	test   %edi,%edi
f01049e8:	74 0c                	je     f01049f6 <readline+0xb6>
				cputchar('\n');
f01049ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01049f1:	e8 52 bd ff ff       	call   f0100748 <cputchar>
			buf[i] = 0;
f01049f6:	c6 86 e0 2a 1a f0 00 	movb   $0x0,-0xfe5d520(%esi)
			return buf;
f01049fd:	b8 e0 2a 1a f0       	mov    $0xf01a2ae0,%eax
		}
	}
}
f0104a02:	83 c4 1c             	add    $0x1c,%esp
f0104a05:	5b                   	pop    %ebx
f0104a06:	5e                   	pop    %esi
f0104a07:	5f                   	pop    %edi
f0104a08:	5d                   	pop    %ebp
f0104a09:	c3                   	ret    
f0104a0a:	66 90                	xchg   %ax,%ax
f0104a0c:	66 90                	xchg   %ax,%ax
f0104a0e:	66 90                	xchg   %ax,%ax

f0104a10 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104a10:	55                   	push   %ebp
f0104a11:	89 e5                	mov    %esp,%ebp
f0104a13:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a16:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a1b:	eb 03                	jmp    f0104a20 <strlen+0x10>
		n++;
f0104a1d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104a20:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104a24:	75 f7                	jne    f0104a1d <strlen+0xd>
		n++;
	return n;
}
f0104a26:	5d                   	pop    %ebp
f0104a27:	c3                   	ret    

f0104a28 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104a28:	55                   	push   %ebp
f0104a29:	89 e5                	mov    %esp,%ebp
f0104a2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104a2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a31:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a36:	eb 03                	jmp    f0104a3b <strnlen+0x13>
		n++;
f0104a38:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104a3b:	39 d0                	cmp    %edx,%eax
f0104a3d:	74 06                	je     f0104a45 <strnlen+0x1d>
f0104a3f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104a43:	75 f3                	jne    f0104a38 <strnlen+0x10>
		n++;
	return n;
}
f0104a45:	5d                   	pop    %ebp
f0104a46:	c3                   	ret    

f0104a47 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104a47:	55                   	push   %ebp
f0104a48:	89 e5                	mov    %esp,%ebp
f0104a4a:	53                   	push   %ebx
f0104a4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a4e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104a51:	89 c2                	mov    %eax,%edx
f0104a53:	83 c2 01             	add    $0x1,%edx
f0104a56:	83 c1 01             	add    $0x1,%ecx
f0104a59:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104a5d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104a60:	84 db                	test   %bl,%bl
f0104a62:	75 ef                	jne    f0104a53 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104a64:	5b                   	pop    %ebx
f0104a65:	5d                   	pop    %ebp
f0104a66:	c3                   	ret    

f0104a67 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104a67:	55                   	push   %ebp
f0104a68:	89 e5                	mov    %esp,%ebp
f0104a6a:	53                   	push   %ebx
f0104a6b:	83 ec 08             	sub    $0x8,%esp
f0104a6e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104a71:	89 1c 24             	mov    %ebx,(%esp)
f0104a74:	e8 97 ff ff ff       	call   f0104a10 <strlen>
	strcpy(dst + len, src);
f0104a79:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a7c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a80:	01 d8                	add    %ebx,%eax
f0104a82:	89 04 24             	mov    %eax,(%esp)
f0104a85:	e8 bd ff ff ff       	call   f0104a47 <strcpy>
	return dst;
}
f0104a8a:	89 d8                	mov    %ebx,%eax
f0104a8c:	83 c4 08             	add    $0x8,%esp
f0104a8f:	5b                   	pop    %ebx
f0104a90:	5d                   	pop    %ebp
f0104a91:	c3                   	ret    

f0104a92 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104a92:	55                   	push   %ebp
f0104a93:	89 e5                	mov    %esp,%ebp
f0104a95:	56                   	push   %esi
f0104a96:	53                   	push   %ebx
f0104a97:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a9a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104a9d:	89 f3                	mov    %esi,%ebx
f0104a9f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104aa2:	89 f2                	mov    %esi,%edx
f0104aa4:	eb 0f                	jmp    f0104ab5 <strncpy+0x23>
		*dst++ = *src;
f0104aa6:	83 c2 01             	add    $0x1,%edx
f0104aa9:	0f b6 01             	movzbl (%ecx),%eax
f0104aac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104aaf:	80 39 01             	cmpb   $0x1,(%ecx)
f0104ab2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104ab5:	39 da                	cmp    %ebx,%edx
f0104ab7:	75 ed                	jne    f0104aa6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104ab9:	89 f0                	mov    %esi,%eax
f0104abb:	5b                   	pop    %ebx
f0104abc:	5e                   	pop    %esi
f0104abd:	5d                   	pop    %ebp
f0104abe:	c3                   	ret    

f0104abf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104abf:	55                   	push   %ebp
f0104ac0:	89 e5                	mov    %esp,%ebp
f0104ac2:	56                   	push   %esi
f0104ac3:	53                   	push   %ebx
f0104ac4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ac7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104aca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104acd:	89 f0                	mov    %esi,%eax
f0104acf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104ad3:	85 c9                	test   %ecx,%ecx
f0104ad5:	75 0b                	jne    f0104ae2 <strlcpy+0x23>
f0104ad7:	eb 1d                	jmp    f0104af6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104ad9:	83 c0 01             	add    $0x1,%eax
f0104adc:	83 c2 01             	add    $0x1,%edx
f0104adf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104ae2:	39 d8                	cmp    %ebx,%eax
f0104ae4:	74 0b                	je     f0104af1 <strlcpy+0x32>
f0104ae6:	0f b6 0a             	movzbl (%edx),%ecx
f0104ae9:	84 c9                	test   %cl,%cl
f0104aeb:	75 ec                	jne    f0104ad9 <strlcpy+0x1a>
f0104aed:	89 c2                	mov    %eax,%edx
f0104aef:	eb 02                	jmp    f0104af3 <strlcpy+0x34>
f0104af1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104af3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104af6:	29 f0                	sub    %esi,%eax
}
f0104af8:	5b                   	pop    %ebx
f0104af9:	5e                   	pop    %esi
f0104afa:	5d                   	pop    %ebp
f0104afb:	c3                   	ret    

f0104afc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104afc:	55                   	push   %ebp
f0104afd:	89 e5                	mov    %esp,%ebp
f0104aff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104b02:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104b05:	eb 06                	jmp    f0104b0d <strcmp+0x11>
		p++, q++;
f0104b07:	83 c1 01             	add    $0x1,%ecx
f0104b0a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104b0d:	0f b6 01             	movzbl (%ecx),%eax
f0104b10:	84 c0                	test   %al,%al
f0104b12:	74 04                	je     f0104b18 <strcmp+0x1c>
f0104b14:	3a 02                	cmp    (%edx),%al
f0104b16:	74 ef                	je     f0104b07 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b18:	0f b6 c0             	movzbl %al,%eax
f0104b1b:	0f b6 12             	movzbl (%edx),%edx
f0104b1e:	29 d0                	sub    %edx,%eax
}
f0104b20:	5d                   	pop    %ebp
f0104b21:	c3                   	ret    

f0104b22 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104b22:	55                   	push   %ebp
f0104b23:	89 e5                	mov    %esp,%ebp
f0104b25:	53                   	push   %ebx
f0104b26:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b29:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b2c:	89 c3                	mov    %eax,%ebx
f0104b2e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104b31:	eb 06                	jmp    f0104b39 <strncmp+0x17>
		n--, p++, q++;
f0104b33:	83 c0 01             	add    $0x1,%eax
f0104b36:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104b39:	39 d8                	cmp    %ebx,%eax
f0104b3b:	74 15                	je     f0104b52 <strncmp+0x30>
f0104b3d:	0f b6 08             	movzbl (%eax),%ecx
f0104b40:	84 c9                	test   %cl,%cl
f0104b42:	74 04                	je     f0104b48 <strncmp+0x26>
f0104b44:	3a 0a                	cmp    (%edx),%cl
f0104b46:	74 eb                	je     f0104b33 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104b48:	0f b6 00             	movzbl (%eax),%eax
f0104b4b:	0f b6 12             	movzbl (%edx),%edx
f0104b4e:	29 d0                	sub    %edx,%eax
f0104b50:	eb 05                	jmp    f0104b57 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104b52:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104b57:	5b                   	pop    %ebx
f0104b58:	5d                   	pop    %ebp
f0104b59:	c3                   	ret    

f0104b5a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104b5a:	55                   	push   %ebp
f0104b5b:	89 e5                	mov    %esp,%ebp
f0104b5d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b60:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104b64:	eb 07                	jmp    f0104b6d <strchr+0x13>
		if (*s == c)
f0104b66:	38 ca                	cmp    %cl,%dl
f0104b68:	74 0f                	je     f0104b79 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104b6a:	83 c0 01             	add    $0x1,%eax
f0104b6d:	0f b6 10             	movzbl (%eax),%edx
f0104b70:	84 d2                	test   %dl,%dl
f0104b72:	75 f2                	jne    f0104b66 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104b74:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104b79:	5d                   	pop    %ebp
f0104b7a:	c3                   	ret    

f0104b7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104b7b:	55                   	push   %ebp
f0104b7c:	89 e5                	mov    %esp,%ebp
f0104b7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b81:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104b85:	eb 07                	jmp    f0104b8e <strfind+0x13>
		if (*s == c)
f0104b87:	38 ca                	cmp    %cl,%dl
f0104b89:	74 0a                	je     f0104b95 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104b8b:	83 c0 01             	add    $0x1,%eax
f0104b8e:	0f b6 10             	movzbl (%eax),%edx
f0104b91:	84 d2                	test   %dl,%dl
f0104b93:	75 f2                	jne    f0104b87 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104b95:	5d                   	pop    %ebp
f0104b96:	c3                   	ret    

f0104b97 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104b97:	55                   	push   %ebp
f0104b98:	89 e5                	mov    %esp,%ebp
f0104b9a:	57                   	push   %edi
f0104b9b:	56                   	push   %esi
f0104b9c:	53                   	push   %ebx
f0104b9d:	8b 55 08             	mov    0x8(%ebp),%edx
f0104ba0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0104ba3:	85 c9                	test   %ecx,%ecx
f0104ba5:	74 37                	je     f0104bde <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104ba7:	f6 c2 03             	test   $0x3,%dl
f0104baa:	75 2a                	jne    f0104bd6 <memset+0x3f>
f0104bac:	f6 c1 03             	test   $0x3,%cl
f0104baf:	75 25                	jne    f0104bd6 <memset+0x3f>
		c &= 0xFF;
f0104bb1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104bb5:	89 fb                	mov    %edi,%ebx
f0104bb7:	c1 e3 08             	shl    $0x8,%ebx
f0104bba:	89 fe                	mov    %edi,%esi
f0104bbc:	c1 e6 18             	shl    $0x18,%esi
f0104bbf:	89 f8                	mov    %edi,%eax
f0104bc1:	c1 e0 10             	shl    $0x10,%eax
f0104bc4:	09 f0                	or     %esi,%eax
f0104bc6:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0104bc8:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104bcb:	89 f8                	mov    %edi,%eax
f0104bcd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
f0104bcf:	89 d7                	mov    %edx,%edi
f0104bd1:	fc                   	cld    
f0104bd2:	f3 ab                	rep stos %eax,%es:(%edi)
f0104bd4:	eb 08                	jmp    f0104bde <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104bd6:	89 d7                	mov    %edx,%edi
f0104bd8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bdb:	fc                   	cld    
f0104bdc:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f0104bde:	89 d0                	mov    %edx,%eax
f0104be0:	5b                   	pop    %ebx
f0104be1:	5e                   	pop    %esi
f0104be2:	5f                   	pop    %edi
f0104be3:	5d                   	pop    %ebp
f0104be4:	c3                   	ret    

f0104be5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104be5:	55                   	push   %ebp
f0104be6:	89 e5                	mov    %esp,%ebp
f0104be8:	57                   	push   %edi
f0104be9:	56                   	push   %esi
f0104bea:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bed:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bf0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104bf3:	39 c6                	cmp    %eax,%esi
f0104bf5:	73 35                	jae    f0104c2c <memmove+0x47>
f0104bf7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104bfa:	39 d0                	cmp    %edx,%eax
f0104bfc:	73 2e                	jae    f0104c2c <memmove+0x47>
		s += n;
		d += n;
f0104bfe:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104c01:	89 d6                	mov    %edx,%esi
f0104c03:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c05:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104c0b:	75 13                	jne    f0104c20 <memmove+0x3b>
f0104c0d:	f6 c1 03             	test   $0x3,%cl
f0104c10:	75 0e                	jne    f0104c20 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104c12:	83 ef 04             	sub    $0x4,%edi
f0104c15:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104c18:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104c1b:	fd                   	std    
f0104c1c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c1e:	eb 09                	jmp    f0104c29 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104c20:	83 ef 01             	sub    $0x1,%edi
f0104c23:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104c26:	fd                   	std    
f0104c27:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104c29:	fc                   	cld    
f0104c2a:	eb 1d                	jmp    f0104c49 <memmove+0x64>
f0104c2c:	89 f2                	mov    %esi,%edx
f0104c2e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104c30:	f6 c2 03             	test   $0x3,%dl
f0104c33:	75 0f                	jne    f0104c44 <memmove+0x5f>
f0104c35:	f6 c1 03             	test   $0x3,%cl
f0104c38:	75 0a                	jne    f0104c44 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104c3a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104c3d:	89 c7                	mov    %eax,%edi
f0104c3f:	fc                   	cld    
f0104c40:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104c42:	eb 05                	jmp    f0104c49 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104c44:	89 c7                	mov    %eax,%edi
f0104c46:	fc                   	cld    
f0104c47:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104c49:	5e                   	pop    %esi
f0104c4a:	5f                   	pop    %edi
f0104c4b:	5d                   	pop    %ebp
f0104c4c:	c3                   	ret    

f0104c4d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104c4d:	55                   	push   %ebp
f0104c4e:	89 e5                	mov    %esp,%ebp
f0104c50:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104c53:	8b 45 10             	mov    0x10(%ebp),%eax
f0104c56:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104c5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c5d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c61:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c64:	89 04 24             	mov    %eax,(%esp)
f0104c67:	e8 79 ff ff ff       	call   f0104be5 <memmove>
}
f0104c6c:	c9                   	leave  
f0104c6d:	c3                   	ret    

f0104c6e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104c6e:	55                   	push   %ebp
f0104c6f:	89 e5                	mov    %esp,%ebp
f0104c71:	56                   	push   %esi
f0104c72:	53                   	push   %ebx
f0104c73:	8b 55 08             	mov    0x8(%ebp),%edx
f0104c76:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c79:	89 d6                	mov    %edx,%esi
f0104c7b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104c7e:	eb 1a                	jmp    f0104c9a <memcmp+0x2c>
		if (*s1 != *s2)
f0104c80:	0f b6 02             	movzbl (%edx),%eax
f0104c83:	0f b6 19             	movzbl (%ecx),%ebx
f0104c86:	38 d8                	cmp    %bl,%al
f0104c88:	74 0a                	je     f0104c94 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104c8a:	0f b6 c0             	movzbl %al,%eax
f0104c8d:	0f b6 db             	movzbl %bl,%ebx
f0104c90:	29 d8                	sub    %ebx,%eax
f0104c92:	eb 0f                	jmp    f0104ca3 <memcmp+0x35>
		s1++, s2++;
f0104c94:	83 c2 01             	add    $0x1,%edx
f0104c97:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104c9a:	39 f2                	cmp    %esi,%edx
f0104c9c:	75 e2                	jne    f0104c80 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104c9e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ca3:	5b                   	pop    %ebx
f0104ca4:	5e                   	pop    %esi
f0104ca5:	5d                   	pop    %ebp
f0104ca6:	c3                   	ret    

f0104ca7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104ca7:	55                   	push   %ebp
f0104ca8:	89 e5                	mov    %esp,%ebp
f0104caa:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104cb0:	89 c2                	mov    %eax,%edx
f0104cb2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104cb5:	eb 07                	jmp    f0104cbe <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104cb7:	38 08                	cmp    %cl,(%eax)
f0104cb9:	74 07                	je     f0104cc2 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104cbb:	83 c0 01             	add    $0x1,%eax
f0104cbe:	39 d0                	cmp    %edx,%eax
f0104cc0:	72 f5                	jb     f0104cb7 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104cc2:	5d                   	pop    %ebp
f0104cc3:	c3                   	ret    

f0104cc4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104cc4:	55                   	push   %ebp
f0104cc5:	89 e5                	mov    %esp,%ebp
f0104cc7:	57                   	push   %edi
f0104cc8:	56                   	push   %esi
f0104cc9:	53                   	push   %ebx
f0104cca:	8b 55 08             	mov    0x8(%ebp),%edx
f0104ccd:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104cd0:	eb 03                	jmp    f0104cd5 <strtol+0x11>
		s++;
f0104cd2:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104cd5:	0f b6 0a             	movzbl (%edx),%ecx
f0104cd8:	80 f9 09             	cmp    $0x9,%cl
f0104cdb:	74 f5                	je     f0104cd2 <strtol+0xe>
f0104cdd:	80 f9 20             	cmp    $0x20,%cl
f0104ce0:	74 f0                	je     f0104cd2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104ce2:	80 f9 2b             	cmp    $0x2b,%cl
f0104ce5:	75 0a                	jne    f0104cf1 <strtol+0x2d>
		s++;
f0104ce7:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104cea:	bf 00 00 00 00       	mov    $0x0,%edi
f0104cef:	eb 11                	jmp    f0104d02 <strtol+0x3e>
f0104cf1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104cf6:	80 f9 2d             	cmp    $0x2d,%cl
f0104cf9:	75 07                	jne    f0104d02 <strtol+0x3e>
		s++, neg = 1;
f0104cfb:	8d 52 01             	lea    0x1(%edx),%edx
f0104cfe:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104d02:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104d07:	75 15                	jne    f0104d1e <strtol+0x5a>
f0104d09:	80 3a 30             	cmpb   $0x30,(%edx)
f0104d0c:	75 10                	jne    f0104d1e <strtol+0x5a>
f0104d0e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104d12:	75 0a                	jne    f0104d1e <strtol+0x5a>
		s += 2, base = 16;
f0104d14:	83 c2 02             	add    $0x2,%edx
f0104d17:	b8 10 00 00 00       	mov    $0x10,%eax
f0104d1c:	eb 10                	jmp    f0104d2e <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104d1e:	85 c0                	test   %eax,%eax
f0104d20:	75 0c                	jne    f0104d2e <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104d22:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104d24:	80 3a 30             	cmpb   $0x30,(%edx)
f0104d27:	75 05                	jne    f0104d2e <strtol+0x6a>
		s++, base = 8;
f0104d29:	83 c2 01             	add    $0x1,%edx
f0104d2c:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104d2e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104d33:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104d36:	0f b6 0a             	movzbl (%edx),%ecx
f0104d39:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104d3c:	89 f0                	mov    %esi,%eax
f0104d3e:	3c 09                	cmp    $0x9,%al
f0104d40:	77 08                	ja     f0104d4a <strtol+0x86>
			dig = *s - '0';
f0104d42:	0f be c9             	movsbl %cl,%ecx
f0104d45:	83 e9 30             	sub    $0x30,%ecx
f0104d48:	eb 20                	jmp    f0104d6a <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104d4a:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104d4d:	89 f0                	mov    %esi,%eax
f0104d4f:	3c 19                	cmp    $0x19,%al
f0104d51:	77 08                	ja     f0104d5b <strtol+0x97>
			dig = *s - 'a' + 10;
f0104d53:	0f be c9             	movsbl %cl,%ecx
f0104d56:	83 e9 57             	sub    $0x57,%ecx
f0104d59:	eb 0f                	jmp    f0104d6a <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104d5b:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104d5e:	89 f0                	mov    %esi,%eax
f0104d60:	3c 19                	cmp    $0x19,%al
f0104d62:	77 16                	ja     f0104d7a <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104d64:	0f be c9             	movsbl %cl,%ecx
f0104d67:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104d6a:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104d6d:	7d 0f                	jge    f0104d7e <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104d6f:	83 c2 01             	add    $0x1,%edx
f0104d72:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104d76:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104d78:	eb bc                	jmp    f0104d36 <strtol+0x72>
f0104d7a:	89 d8                	mov    %ebx,%eax
f0104d7c:	eb 02                	jmp    f0104d80 <strtol+0xbc>
f0104d7e:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104d80:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104d84:	74 05                	je     f0104d8b <strtol+0xc7>
		*endptr = (char *) s;
f0104d86:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d89:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104d8b:	f7 d8                	neg    %eax
f0104d8d:	85 ff                	test   %edi,%edi
f0104d8f:	0f 44 c3             	cmove  %ebx,%eax
}
f0104d92:	5b                   	pop    %ebx
f0104d93:	5e                   	pop    %esi
f0104d94:	5f                   	pop    %edi
f0104d95:	5d                   	pop    %ebp
f0104d96:	c3                   	ret    
f0104d97:	66 90                	xchg   %ax,%ax
f0104d99:	66 90                	xchg   %ax,%ax
f0104d9b:	66 90                	xchg   %ax,%ax
f0104d9d:	66 90                	xchg   %ax,%ax
f0104d9f:	90                   	nop

f0104da0 <__udivdi3>:
f0104da0:	55                   	push   %ebp
f0104da1:	57                   	push   %edi
f0104da2:	56                   	push   %esi
f0104da3:	83 ec 0c             	sub    $0xc,%esp
f0104da6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104daa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104dae:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104db2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104db6:	85 c0                	test   %eax,%eax
f0104db8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104dbc:	89 ea                	mov    %ebp,%edx
f0104dbe:	89 0c 24             	mov    %ecx,(%esp)
f0104dc1:	75 2d                	jne    f0104df0 <__udivdi3+0x50>
f0104dc3:	39 e9                	cmp    %ebp,%ecx
f0104dc5:	77 61                	ja     f0104e28 <__udivdi3+0x88>
f0104dc7:	85 c9                	test   %ecx,%ecx
f0104dc9:	89 ce                	mov    %ecx,%esi
f0104dcb:	75 0b                	jne    f0104dd8 <__udivdi3+0x38>
f0104dcd:	b8 01 00 00 00       	mov    $0x1,%eax
f0104dd2:	31 d2                	xor    %edx,%edx
f0104dd4:	f7 f1                	div    %ecx
f0104dd6:	89 c6                	mov    %eax,%esi
f0104dd8:	31 d2                	xor    %edx,%edx
f0104dda:	89 e8                	mov    %ebp,%eax
f0104ddc:	f7 f6                	div    %esi
f0104dde:	89 c5                	mov    %eax,%ebp
f0104de0:	89 f8                	mov    %edi,%eax
f0104de2:	f7 f6                	div    %esi
f0104de4:	89 ea                	mov    %ebp,%edx
f0104de6:	83 c4 0c             	add    $0xc,%esp
f0104de9:	5e                   	pop    %esi
f0104dea:	5f                   	pop    %edi
f0104deb:	5d                   	pop    %ebp
f0104dec:	c3                   	ret    
f0104ded:	8d 76 00             	lea    0x0(%esi),%esi
f0104df0:	39 e8                	cmp    %ebp,%eax
f0104df2:	77 24                	ja     f0104e18 <__udivdi3+0x78>
f0104df4:	0f bd e8             	bsr    %eax,%ebp
f0104df7:	83 f5 1f             	xor    $0x1f,%ebp
f0104dfa:	75 3c                	jne    f0104e38 <__udivdi3+0x98>
f0104dfc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104e00:	39 34 24             	cmp    %esi,(%esp)
f0104e03:	0f 86 9f 00 00 00    	jbe    f0104ea8 <__udivdi3+0x108>
f0104e09:	39 d0                	cmp    %edx,%eax
f0104e0b:	0f 82 97 00 00 00    	jb     f0104ea8 <__udivdi3+0x108>
f0104e11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104e18:	31 d2                	xor    %edx,%edx
f0104e1a:	31 c0                	xor    %eax,%eax
f0104e1c:	83 c4 0c             	add    $0xc,%esp
f0104e1f:	5e                   	pop    %esi
f0104e20:	5f                   	pop    %edi
f0104e21:	5d                   	pop    %ebp
f0104e22:	c3                   	ret    
f0104e23:	90                   	nop
f0104e24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104e28:	89 f8                	mov    %edi,%eax
f0104e2a:	f7 f1                	div    %ecx
f0104e2c:	31 d2                	xor    %edx,%edx
f0104e2e:	83 c4 0c             	add    $0xc,%esp
f0104e31:	5e                   	pop    %esi
f0104e32:	5f                   	pop    %edi
f0104e33:	5d                   	pop    %ebp
f0104e34:	c3                   	ret    
f0104e35:	8d 76 00             	lea    0x0(%esi),%esi
f0104e38:	89 e9                	mov    %ebp,%ecx
f0104e3a:	8b 3c 24             	mov    (%esp),%edi
f0104e3d:	d3 e0                	shl    %cl,%eax
f0104e3f:	89 c6                	mov    %eax,%esi
f0104e41:	b8 20 00 00 00       	mov    $0x20,%eax
f0104e46:	29 e8                	sub    %ebp,%eax
f0104e48:	89 c1                	mov    %eax,%ecx
f0104e4a:	d3 ef                	shr    %cl,%edi
f0104e4c:	89 e9                	mov    %ebp,%ecx
f0104e4e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104e52:	8b 3c 24             	mov    (%esp),%edi
f0104e55:	09 74 24 08          	or     %esi,0x8(%esp)
f0104e59:	89 d6                	mov    %edx,%esi
f0104e5b:	d3 e7                	shl    %cl,%edi
f0104e5d:	89 c1                	mov    %eax,%ecx
f0104e5f:	89 3c 24             	mov    %edi,(%esp)
f0104e62:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104e66:	d3 ee                	shr    %cl,%esi
f0104e68:	89 e9                	mov    %ebp,%ecx
f0104e6a:	d3 e2                	shl    %cl,%edx
f0104e6c:	89 c1                	mov    %eax,%ecx
f0104e6e:	d3 ef                	shr    %cl,%edi
f0104e70:	09 d7                	or     %edx,%edi
f0104e72:	89 f2                	mov    %esi,%edx
f0104e74:	89 f8                	mov    %edi,%eax
f0104e76:	f7 74 24 08          	divl   0x8(%esp)
f0104e7a:	89 d6                	mov    %edx,%esi
f0104e7c:	89 c7                	mov    %eax,%edi
f0104e7e:	f7 24 24             	mull   (%esp)
f0104e81:	39 d6                	cmp    %edx,%esi
f0104e83:	89 14 24             	mov    %edx,(%esp)
f0104e86:	72 30                	jb     f0104eb8 <__udivdi3+0x118>
f0104e88:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104e8c:	89 e9                	mov    %ebp,%ecx
f0104e8e:	d3 e2                	shl    %cl,%edx
f0104e90:	39 c2                	cmp    %eax,%edx
f0104e92:	73 05                	jae    f0104e99 <__udivdi3+0xf9>
f0104e94:	3b 34 24             	cmp    (%esp),%esi
f0104e97:	74 1f                	je     f0104eb8 <__udivdi3+0x118>
f0104e99:	89 f8                	mov    %edi,%eax
f0104e9b:	31 d2                	xor    %edx,%edx
f0104e9d:	e9 7a ff ff ff       	jmp    f0104e1c <__udivdi3+0x7c>
f0104ea2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104ea8:	31 d2                	xor    %edx,%edx
f0104eaa:	b8 01 00 00 00       	mov    $0x1,%eax
f0104eaf:	e9 68 ff ff ff       	jmp    f0104e1c <__udivdi3+0x7c>
f0104eb4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104eb8:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104ebb:	31 d2                	xor    %edx,%edx
f0104ebd:	83 c4 0c             	add    $0xc,%esp
f0104ec0:	5e                   	pop    %esi
f0104ec1:	5f                   	pop    %edi
f0104ec2:	5d                   	pop    %ebp
f0104ec3:	c3                   	ret    
f0104ec4:	66 90                	xchg   %ax,%ax
f0104ec6:	66 90                	xchg   %ax,%ax
f0104ec8:	66 90                	xchg   %ax,%ax
f0104eca:	66 90                	xchg   %ax,%ax
f0104ecc:	66 90                	xchg   %ax,%ax
f0104ece:	66 90                	xchg   %ax,%ax

f0104ed0 <__umoddi3>:
f0104ed0:	55                   	push   %ebp
f0104ed1:	57                   	push   %edi
f0104ed2:	56                   	push   %esi
f0104ed3:	83 ec 14             	sub    $0x14,%esp
f0104ed6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104eda:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104ede:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104ee2:	89 c7                	mov    %eax,%edi
f0104ee4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ee8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104eec:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104ef0:	89 34 24             	mov    %esi,(%esp)
f0104ef3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104ef7:	85 c0                	test   %eax,%eax
f0104ef9:	89 c2                	mov    %eax,%edx
f0104efb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104eff:	75 17                	jne    f0104f18 <__umoddi3+0x48>
f0104f01:	39 fe                	cmp    %edi,%esi
f0104f03:	76 4b                	jbe    f0104f50 <__umoddi3+0x80>
f0104f05:	89 c8                	mov    %ecx,%eax
f0104f07:	89 fa                	mov    %edi,%edx
f0104f09:	f7 f6                	div    %esi
f0104f0b:	89 d0                	mov    %edx,%eax
f0104f0d:	31 d2                	xor    %edx,%edx
f0104f0f:	83 c4 14             	add    $0x14,%esp
f0104f12:	5e                   	pop    %esi
f0104f13:	5f                   	pop    %edi
f0104f14:	5d                   	pop    %ebp
f0104f15:	c3                   	ret    
f0104f16:	66 90                	xchg   %ax,%ax
f0104f18:	39 f8                	cmp    %edi,%eax
f0104f1a:	77 54                	ja     f0104f70 <__umoddi3+0xa0>
f0104f1c:	0f bd e8             	bsr    %eax,%ebp
f0104f1f:	83 f5 1f             	xor    $0x1f,%ebp
f0104f22:	75 5c                	jne    f0104f80 <__umoddi3+0xb0>
f0104f24:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104f28:	39 3c 24             	cmp    %edi,(%esp)
f0104f2b:	0f 87 e7 00 00 00    	ja     f0105018 <__umoddi3+0x148>
f0104f31:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104f35:	29 f1                	sub    %esi,%ecx
f0104f37:	19 c7                	sbb    %eax,%edi
f0104f39:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f3d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104f41:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104f45:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104f49:	83 c4 14             	add    $0x14,%esp
f0104f4c:	5e                   	pop    %esi
f0104f4d:	5f                   	pop    %edi
f0104f4e:	5d                   	pop    %ebp
f0104f4f:	c3                   	ret    
f0104f50:	85 f6                	test   %esi,%esi
f0104f52:	89 f5                	mov    %esi,%ebp
f0104f54:	75 0b                	jne    f0104f61 <__umoddi3+0x91>
f0104f56:	b8 01 00 00 00       	mov    $0x1,%eax
f0104f5b:	31 d2                	xor    %edx,%edx
f0104f5d:	f7 f6                	div    %esi
f0104f5f:	89 c5                	mov    %eax,%ebp
f0104f61:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104f65:	31 d2                	xor    %edx,%edx
f0104f67:	f7 f5                	div    %ebp
f0104f69:	89 c8                	mov    %ecx,%eax
f0104f6b:	f7 f5                	div    %ebp
f0104f6d:	eb 9c                	jmp    f0104f0b <__umoddi3+0x3b>
f0104f6f:	90                   	nop
f0104f70:	89 c8                	mov    %ecx,%eax
f0104f72:	89 fa                	mov    %edi,%edx
f0104f74:	83 c4 14             	add    $0x14,%esp
f0104f77:	5e                   	pop    %esi
f0104f78:	5f                   	pop    %edi
f0104f79:	5d                   	pop    %ebp
f0104f7a:	c3                   	ret    
f0104f7b:	90                   	nop
f0104f7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f80:	8b 04 24             	mov    (%esp),%eax
f0104f83:	be 20 00 00 00       	mov    $0x20,%esi
f0104f88:	89 e9                	mov    %ebp,%ecx
f0104f8a:	29 ee                	sub    %ebp,%esi
f0104f8c:	d3 e2                	shl    %cl,%edx
f0104f8e:	89 f1                	mov    %esi,%ecx
f0104f90:	d3 e8                	shr    %cl,%eax
f0104f92:	89 e9                	mov    %ebp,%ecx
f0104f94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f98:	8b 04 24             	mov    (%esp),%eax
f0104f9b:	09 54 24 04          	or     %edx,0x4(%esp)
f0104f9f:	89 fa                	mov    %edi,%edx
f0104fa1:	d3 e0                	shl    %cl,%eax
f0104fa3:	89 f1                	mov    %esi,%ecx
f0104fa5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104fa9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104fad:	d3 ea                	shr    %cl,%edx
f0104faf:	89 e9                	mov    %ebp,%ecx
f0104fb1:	d3 e7                	shl    %cl,%edi
f0104fb3:	89 f1                	mov    %esi,%ecx
f0104fb5:	d3 e8                	shr    %cl,%eax
f0104fb7:	89 e9                	mov    %ebp,%ecx
f0104fb9:	09 f8                	or     %edi,%eax
f0104fbb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0104fbf:	f7 74 24 04          	divl   0x4(%esp)
f0104fc3:	d3 e7                	shl    %cl,%edi
f0104fc5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104fc9:	89 d7                	mov    %edx,%edi
f0104fcb:	f7 64 24 08          	mull   0x8(%esp)
f0104fcf:	39 d7                	cmp    %edx,%edi
f0104fd1:	89 c1                	mov    %eax,%ecx
f0104fd3:	89 14 24             	mov    %edx,(%esp)
f0104fd6:	72 2c                	jb     f0105004 <__umoddi3+0x134>
f0104fd8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0104fdc:	72 22                	jb     f0105000 <__umoddi3+0x130>
f0104fde:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104fe2:	29 c8                	sub    %ecx,%eax
f0104fe4:	19 d7                	sbb    %edx,%edi
f0104fe6:	89 e9                	mov    %ebp,%ecx
f0104fe8:	89 fa                	mov    %edi,%edx
f0104fea:	d3 e8                	shr    %cl,%eax
f0104fec:	89 f1                	mov    %esi,%ecx
f0104fee:	d3 e2                	shl    %cl,%edx
f0104ff0:	89 e9                	mov    %ebp,%ecx
f0104ff2:	d3 ef                	shr    %cl,%edi
f0104ff4:	09 d0                	or     %edx,%eax
f0104ff6:	89 fa                	mov    %edi,%edx
f0104ff8:	83 c4 14             	add    $0x14,%esp
f0104ffb:	5e                   	pop    %esi
f0104ffc:	5f                   	pop    %edi
f0104ffd:	5d                   	pop    %ebp
f0104ffe:	c3                   	ret    
f0104fff:	90                   	nop
f0105000:	39 d7                	cmp    %edx,%edi
f0105002:	75 da                	jne    f0104fde <__umoddi3+0x10e>
f0105004:	8b 14 24             	mov    (%esp),%edx
f0105007:	89 c1                	mov    %eax,%ecx
f0105009:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010500d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0105011:	eb cb                	jmp    f0104fde <__umoddi3+0x10e>
f0105013:	90                   	nop
f0105014:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105018:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010501c:	0f 82 0f ff ff ff    	jb     f0104f31 <__umoddi3+0x61>
f0105022:	e9 1a ff ff ff       	jmp    f0104f41 <__umoddi3+0x71>
