
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

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
f0100015:	b8 00 e0 10 00       	mov    $0x10e000,%eax
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
f010003d:	bc 00 e0 10 f0       	mov    $0xf010e000,%esp

	# now to C code
	call	i386_init
f0100042:	e8 02 00 00 00       	call   f0100049 <i386_init>

f0100047 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f0100047:	eb fe                	jmp    f0100047 <spin>

f0100049 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100049:	55                   	push   %ebp
f010004a:	89 e5                	mov    %esp,%ebp
f010004c:	83 ec 0c             	sub    $0xc,%esp
	extern char __bss_start[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(__bss_start, 0, end - __bss_start);
f010004f:	b8 b0 6a 19 f0       	mov    $0xf0196ab0,%eax
f0100054:	2d a0 4b 19 f0       	sub    $0xf0194ba0,%eax
f0100059:	50                   	push   %eax
f010005a:	6a 00                	push   $0x0
f010005c:	68 a0 4b 19 f0       	push   $0xf0194ba0
f0100061:	e8 1d 3e 00 00       	call   f0103e83 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100066:	e8 8d 06 00 00       	call   f01006f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006b:	83 c4 08             	add    $0x8,%esp
f010006e:	68 ac 1a 00 00       	push   $0x1aac
f0100073:	68 20 43 10 f0       	push   $0xf0104320
f0100078:	e8 52 2f 00 00       	call   f0102fcf <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f010007d:	e8 44 25 00 00       	call   f01025c6 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100082:	e8 29 2b 00 00       	call   f0102bb0 <env_init>
	trap_init();
f0100087:	e8 fa 2f 00 00       	call   f0103086 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010008c:	83 c4 08             	add    $0x8,%esp
f010008f:	6a 00                	push   $0x0
f0100091:	68 56 f3 10 f0       	push   $0xf010f356
f0100096:	e8 43 2c 00 00       	call   f0102cde <env_create>
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f010009b:	83 c4 04             	add    $0x4,%esp
f010009e:	ff 35 e4 4d 19 f0    	pushl  0xf0194de4
f01000a4:	e8 05 2e 00 00       	call   f0102eae <env_run>

f01000a9 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000a9:	55                   	push   %ebp
f01000aa:	89 e5                	mov    %esp,%ebp
f01000ac:	56                   	push   %esi
f01000ad:	53                   	push   %ebx
f01000ae:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000b1:	83 3d a0 6a 19 f0 00 	cmpl   $0x0,0xf0196aa0
f01000b8:	75 37                	jne    f01000f1 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000ba:	89 35 a0 6a 19 f0    	mov    %esi,0xf0196aa0

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000c0:	fa                   	cli    
f01000c1:	fc                   	cld    

	va_start(ap, fmt);
f01000c2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf(">>>\n>>> kernel panic at %s:%d: ", file, line);
f01000c5:	83 ec 04             	sub    $0x4,%esp
f01000c8:	ff 75 0c             	pushl  0xc(%ebp)
f01000cb:	ff 75 08             	pushl  0x8(%ebp)
f01000ce:	68 5c 43 10 f0       	push   $0xf010435c
f01000d3:	e8 f7 2e 00 00       	call   f0102fcf <cprintf>
	vcprintf(fmt, ap);
f01000d8:	83 c4 08             	add    $0x8,%esp
f01000db:	53                   	push   %ebx
f01000dc:	56                   	push   %esi
f01000dd:	e8 c7 2e 00 00       	call   f0102fa9 <vcprintf>
	cprintf("\n>>>\n");
f01000e2:	c7 04 24 3b 43 10 f0 	movl   $0xf010433b,(%esp)
f01000e9:	e8 e1 2e 00 00       	call   f0102fcf <cprintf>
	va_end(ap);
f01000ee:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000f1:	83 ec 0c             	sub    $0xc,%esp
f01000f4:	6a 00                	push   $0x0
f01000f6:	e8 cb 08 00 00       	call   f01009c6 <monitor>
f01000fb:	83 c4 10             	add    $0x10,%esp
f01000fe:	eb f1                	jmp    f01000f1 <_panic+0x48>

f0100100 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100100:	55                   	push   %ebp
f0100101:	89 e5                	mov    %esp,%ebp
f0100103:	53                   	push   %ebx
f0100104:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100107:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010010a:	ff 75 0c             	pushl  0xc(%ebp)
f010010d:	ff 75 08             	pushl  0x8(%ebp)
f0100110:	68 41 43 10 f0       	push   $0xf0104341
f0100115:	e8 b5 2e 00 00       	call   f0102fcf <cprintf>
	vcprintf(fmt, ap);
f010011a:	83 c4 08             	add    $0x8,%esp
f010011d:	53                   	push   %ebx
f010011e:	ff 75 10             	pushl  0x10(%ebp)
f0100121:	e8 83 2e 00 00       	call   f0102fa9 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 8a 53 10 f0 	movl   $0xf010538a,(%esp)
f010012d:	e8 9d 2e 00 00       	call   f0102fcf <cprintf>
	va_end(ap);
}
f0100132:	83 c4 10             	add    $0x10,%esp
f0100135:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100138:	c9                   	leave  
f0100139:	c3                   	ret    

f010013a <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f010013a:	55                   	push   %ebp
f010013b:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013d:	89 c2                	mov    %eax,%edx
f010013f:	ec                   	in     (%dx),%al
	return data;
}
f0100140:	5d                   	pop    %ebp
f0100141:	c3                   	ret    

f0100142 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0100142:	55                   	push   %ebp
f0100143:	89 e5                	mov    %esp,%ebp
f0100145:	89 c1                	mov    %eax,%ecx
f0100147:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100149:	89 ca                	mov    %ecx,%edx
f010014b:	ee                   	out    %al,(%dx)
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
	inb(0x84);
f0100151:	b8 84 00 00 00       	mov    $0x84,%eax
f0100156:	e8 df ff ff ff       	call   f010013a <inb>
	inb(0x84);
f010015b:	b8 84 00 00 00       	mov    $0x84,%eax
f0100160:	e8 d5 ff ff ff       	call   f010013a <inb>
	inb(0x84);
f0100165:	b8 84 00 00 00       	mov    $0x84,%eax
f010016a:	e8 cb ff ff ff       	call   f010013a <inb>
	inb(0x84);
f010016f:	b8 84 00 00 00       	mov    $0x84,%eax
f0100174:	e8 c1 ff ff ff       	call   f010013a <inb>
}
f0100179:	5d                   	pop    %ebp
f010017a:	c3                   	ret    

f010017b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010017b:	55                   	push   %ebp
f010017c:	89 e5                	mov    %esp,%ebp
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010017e:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100183:	e8 b2 ff ff ff       	call   f010013a <inb>
f0100188:	a8 01                	test   $0x1,%al
f010018a:	74 0f                	je     f010019b <serial_proc_data+0x20>
		return -1;
	return inb(COM1+COM_RX);
f010018c:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f0100191:	e8 a4 ff ff ff       	call   f010013a <inb>
f0100196:	0f b6 c0             	movzbl %al,%eax
f0100199:	eb 05                	jmp    f01001a0 <serial_proc_data+0x25>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010019b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001a0:	5d                   	pop    %ebp
f01001a1:	c3                   	ret    

f01001a2 <serial_putc>:
		cons_intr(serial_proc_data);
}

static void
serial_putc(int c)
{
f01001a2:	55                   	push   %ebp
f01001a3:	89 e5                	mov    %esp,%ebp
f01001a5:	56                   	push   %esi
f01001a6:	53                   	push   %ebx
f01001a7:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0;
f01001a9:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001ae:	eb 08                	jmp    f01001b8 <serial_putc+0x16>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001b0:	e8 99 ff ff ff       	call   f010014e <delay>
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01001b5:	83 c3 01             	add    $0x1,%ebx
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001b8:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f01001bd:	e8 78 ff ff ff       	call   f010013a <inb>
f01001c2:	a8 20                	test   $0x20,%al
f01001c4:	75 08                	jne    f01001ce <serial_putc+0x2c>
f01001c6:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01001cc:	7e e2                	jle    f01001b0 <serial_putc+0xe>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001ce:	89 f0                	mov    %esi,%eax
f01001d0:	0f b6 d0             	movzbl %al,%edx
f01001d3:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f01001d8:	e8 65 ff ff ff       	call   f0100142 <outb>
}
f01001dd:	5b                   	pop    %ebx
f01001de:	5e                   	pop    %esi
f01001df:	5d                   	pop    %ebp
f01001e0:	c3                   	ret    

f01001e1 <serial_init>:

static void
serial_init(void)
{
f01001e1:	55                   	push   %ebp
f01001e2:	89 e5                	mov    %esp,%ebp
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
f01001e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01001e9:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f01001ee:	e8 4f ff ff ff       	call   f0100142 <outb>

	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
f01001f3:	ba 80 00 00 00       	mov    $0x80,%edx
f01001f8:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f01001fd:	e8 40 ff ff ff       	call   f0100142 <outb>
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
f0100202:	ba 0c 00 00 00       	mov    $0xc,%edx
f0100207:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010020c:	e8 31 ff ff ff       	call   f0100142 <outb>
	outb(COM1+COM_DLM, 0);
f0100211:	ba 00 00 00 00       	mov    $0x0,%edx
f0100216:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f010021b:	e8 22 ff ff ff       	call   f0100142 <outb>

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);
f0100220:	ba 03 00 00 00       	mov    $0x3,%edx
f0100225:	b8 fb 03 00 00       	mov    $0x3fb,%eax
f010022a:	e8 13 ff ff ff       	call   f0100142 <outb>

	// No modem controls
	outb(COM1+COM_MCR, 0);
f010022f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100234:	b8 fc 03 00 00       	mov    $0x3fc,%eax
f0100239:	e8 04 ff ff ff       	call   f0100142 <outb>
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);
f010023e:	ba 01 00 00 00       	mov    $0x1,%edx
f0100243:	b8 f9 03 00 00       	mov    $0x3f9,%eax
f0100248:	e8 f5 fe ff ff       	call   f0100142 <outb>

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010024d:	b8 fd 03 00 00       	mov    $0x3fd,%eax
f0100252:	e8 e3 fe ff ff       	call   f010013a <inb>
f0100257:	3c ff                	cmp    $0xff,%al
f0100259:	0f 95 05 d4 4d 19 f0 	setne  0xf0194dd4
	(void) inb(COM1+COM_IIR);
f0100260:	b8 fa 03 00 00       	mov    $0x3fa,%eax
f0100265:	e8 d0 fe ff ff       	call   f010013a <inb>
	(void) inb(COM1+COM_RX);
f010026a:	b8 f8 03 00 00       	mov    $0x3f8,%eax
f010026f:	e8 c6 fe ff ff       	call   f010013a <inb>

}
f0100274:	5d                   	pop    %ebp
f0100275:	c3                   	ret    

f0100276 <lpt_putc>:
// For information on PC parallel port programming, see the class References
// page.

static void
lpt_putc(int c)
{
f0100276:	55                   	push   %ebp
f0100277:	89 e5                	mov    %esp,%ebp
f0100279:	56                   	push   %esi
f010027a:	53                   	push   %ebx
f010027b:	89 c6                	mov    %eax,%esi
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010027d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100282:	eb 08                	jmp    f010028c <lpt_putc+0x16>
		delay();
f0100284:	e8 c5 fe ff ff       	call   f010014e <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100289:	83 c3 01             	add    $0x1,%ebx
f010028c:	b8 79 03 00 00       	mov    $0x379,%eax
f0100291:	e8 a4 fe ff ff       	call   f010013a <inb>
f0100296:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010029c:	7f 04                	jg     f01002a2 <lpt_putc+0x2c>
f010029e:	84 c0                	test   %al,%al
f01002a0:	79 e2                	jns    f0100284 <lpt_putc+0xe>
		delay();
	outb(0x378+0, c);
f01002a2:	89 f0                	mov    %esi,%eax
f01002a4:	0f b6 d0             	movzbl %al,%edx
f01002a7:	b8 78 03 00 00       	mov    $0x378,%eax
f01002ac:	e8 91 fe ff ff       	call   f0100142 <outb>
	outb(0x378+2, 0x08|0x04|0x01);
f01002b1:	ba 0d 00 00 00       	mov    $0xd,%edx
f01002b6:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002bb:	e8 82 fe ff ff       	call   f0100142 <outb>
	outb(0x378+2, 0x08);
f01002c0:	ba 08 00 00 00       	mov    $0x8,%edx
f01002c5:	b8 7a 03 00 00       	mov    $0x37a,%eax
f01002ca:	e8 73 fe ff ff       	call   f0100142 <outb>
}
f01002cf:	5b                   	pop    %ebx
f01002d0:	5e                   	pop    %esi
f01002d1:	5d                   	pop    %ebp
f01002d2:	c3                   	ret    

f01002d3 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

static void
cga_init(void)
{
f01002d3:	55                   	push   %ebp
f01002d4:	89 e5                	mov    %esp,%ebp
f01002d6:	57                   	push   %edi
f01002d7:	56                   	push   %esi
f01002d8:	53                   	push   %ebx
f01002d9:	83 ec 04             	sub    $0x4,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01002dc:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01002e3:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01002ea:	5a a5 
	if (*cp != 0xA55A) {
f01002ec:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01002f3:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01002f7:	74 13                	je     f010030c <cga_init+0x39>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01002f9:	c7 05 d0 4d 19 f0 b4 	movl   $0x3b4,0xf0194dd0
f0100300:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100303:	c7 45 f0 00 00 0b f0 	movl   $0xf00b0000,-0x10(%ebp)
f010030a:	eb 18                	jmp    f0100324 <cga_init+0x51>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010030c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100313:	c7 05 d0 4d 19 f0 d4 	movl   $0x3d4,0xf0194dd0
f010031a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010031d:	c7 45 f0 00 80 0b f0 	movl   $0xf00b8000,-0x10(%ebp)
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100324:	8b 35 d0 4d 19 f0    	mov    0xf0194dd0,%esi
f010032a:	ba 0e 00 00 00       	mov    $0xe,%edx
f010032f:	89 f0                	mov    %esi,%eax
f0100331:	e8 0c fe ff ff       	call   f0100142 <outb>
	pos = inb(addr_6845 + 1) << 8;
f0100336:	8d 7e 01             	lea    0x1(%esi),%edi
f0100339:	89 f8                	mov    %edi,%eax
f010033b:	e8 fa fd ff ff       	call   f010013a <inb>
f0100340:	0f b6 d8             	movzbl %al,%ebx
f0100343:	c1 e3 08             	shl    $0x8,%ebx
	outb(addr_6845, 15);
f0100346:	ba 0f 00 00 00       	mov    $0xf,%edx
f010034b:	89 f0                	mov    %esi,%eax
f010034d:	e8 f0 fd ff ff       	call   f0100142 <outb>
	pos |= inb(addr_6845 + 1);
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	e8 e1 fd ff ff       	call   f010013a <inb>

	crt_buf = (uint16_t*) cp;
f0100359:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010035c:	89 0d cc 4d 19 f0    	mov    %ecx,0xf0194dcc
	crt_pos = pos;
f0100362:	0f b6 c0             	movzbl %al,%eax
f0100365:	09 c3                	or     %eax,%ebx
f0100367:	66 89 1d c8 4d 19 f0 	mov    %bx,0xf0194dc8
}
f010036e:	83 c4 04             	add    $0x4,%esp
f0100371:	5b                   	pop    %ebx
f0100372:	5e                   	pop    %esi
f0100373:	5f                   	pop    %edi
f0100374:	5d                   	pop    %ebp
f0100375:	c3                   	ret    

f0100376 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100376:	55                   	push   %ebp
f0100377:	89 e5                	mov    %esp,%ebp
f0100379:	53                   	push   %ebx
f010037a:	83 ec 04             	sub    $0x4,%esp
f010037d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010037f:	eb 2b                	jmp    f01003ac <cons_intr+0x36>
		if (c == 0)
f0100381:	85 c0                	test   %eax,%eax
f0100383:	74 27                	je     f01003ac <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f0100385:	8b 0d c4 4d 19 f0    	mov    0xf0194dc4,%ecx
f010038b:	8d 51 01             	lea    0x1(%ecx),%edx
f010038e:	89 15 c4 4d 19 f0    	mov    %edx,0xf0194dc4
f0100394:	88 81 c0 4b 19 f0    	mov    %al,-0xfe6b440(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010039a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003a0:	75 0a                	jne    f01003ac <cons_intr+0x36>
			cons.wpos = 0;
f01003a2:	c7 05 c4 4d 19 f0 00 	movl   $0x0,0xf0194dc4
f01003a9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003ac:	ff d3                	call   *%ebx
f01003ae:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003b1:	75 ce                	jne    f0100381 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003b3:	83 c4 04             	add    $0x4,%esp
f01003b6:	5b                   	pop    %ebx
f01003b7:	5d                   	pop    %ebp
f01003b8:	c3                   	ret    

f01003b9 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003b9:	55                   	push   %ebp
f01003ba:	89 e5                	mov    %esp,%ebp
f01003bc:	53                   	push   %ebx
f01003bd:	83 ec 04             	sub    $0x4,%esp
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
f01003c0:	b8 64 00 00 00       	mov    $0x64,%eax
f01003c5:	e8 70 fd ff ff       	call   f010013a <inb>
	if ((stat & KBS_DIB) == 0)
f01003ca:	a8 01                	test   $0x1,%al
f01003cc:	0f 84 fe 00 00 00    	je     f01004d0 <kbd_proc_data+0x117>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003d2:	a8 20                	test   $0x20,%al
f01003d4:	0f 85 fd 00 00 00    	jne    f01004d7 <kbd_proc_data+0x11e>
		return -1;

	data = inb(KBDATAP);
f01003da:	b8 60 00 00 00       	mov    $0x60,%eax
f01003df:	e8 56 fd ff ff       	call   f010013a <inb>

	if (data == 0xE0) {
f01003e4:	3c e0                	cmp    $0xe0,%al
f01003e6:	75 11                	jne    f01003f9 <kbd_proc_data+0x40>
		// E0 escape character
		shift |= E0ESC;
f01003e8:	83 0d a0 4b 19 f0 40 	orl    $0x40,0xf0194ba0
		return 0;
f01003ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01003f4:	e9 e7 00 00 00       	jmp    f01004e0 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003f9:	84 c0                	test   %al,%al
f01003fb:	79 38                	jns    f0100435 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003fd:	8b 0d a0 4b 19 f0    	mov    0xf0194ba0,%ecx
f0100403:	89 cb                	mov    %ecx,%ebx
f0100405:	83 e3 40             	and    $0x40,%ebx
f0100408:	89 c2                	mov    %eax,%edx
f010040a:	83 e2 7f             	and    $0x7f,%edx
f010040d:	85 db                	test   %ebx,%ebx
f010040f:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100412:	0f b6 c0             	movzbl %al,%eax
f0100415:	0f b6 80 e0 44 10 f0 	movzbl -0xfefbb20(%eax),%eax
f010041c:	83 c8 40             	or     $0x40,%eax
f010041f:	0f b6 c0             	movzbl %al,%eax
f0100422:	f7 d0                	not    %eax
f0100424:	21 c8                	and    %ecx,%eax
f0100426:	a3 a0 4b 19 f0       	mov    %eax,0xf0194ba0
		return 0;
f010042b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100430:	e9 ab 00 00 00       	jmp    f01004e0 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100435:	8b 15 a0 4b 19 f0    	mov    0xf0194ba0,%edx
f010043b:	f6 c2 40             	test   $0x40,%dl
f010043e:	74 0c                	je     f010044c <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100440:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100443:	83 e2 bf             	and    $0xffffffbf,%edx
f0100446:	89 15 a0 4b 19 f0    	mov    %edx,0xf0194ba0
	}

	shift |= shiftcode[data];
f010044c:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010044f:	0f b6 90 e0 44 10 f0 	movzbl -0xfefbb20(%eax),%edx
f0100456:	0b 15 a0 4b 19 f0    	or     0xf0194ba0,%edx
f010045c:	0f b6 88 e0 43 10 f0 	movzbl -0xfefbc20(%eax),%ecx
f0100463:	31 ca                	xor    %ecx,%edx
f0100465:	89 15 a0 4b 19 f0    	mov    %edx,0xf0194ba0

	c = charcode[shift & (CTL | SHIFT)][data];
f010046b:	89 d1                	mov    %edx,%ecx
f010046d:	83 e1 03             	and    $0x3,%ecx
f0100470:	8b 0c 8d c0 43 10 f0 	mov    -0xfefbc40(,%ecx,4),%ecx
f0100477:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f010047b:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f010047e:	f6 c2 08             	test   $0x8,%dl
f0100481:	74 1b                	je     f010049e <kbd_proc_data+0xe5>
		if ('a' <= c && c <= 'z')
f0100483:	89 d8                	mov    %ebx,%eax
f0100485:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100488:	83 f9 19             	cmp    $0x19,%ecx
f010048b:	77 05                	ja     f0100492 <kbd_proc_data+0xd9>
			c += 'A' - 'a';
f010048d:	83 eb 20             	sub    $0x20,%ebx
f0100490:	eb 0c                	jmp    f010049e <kbd_proc_data+0xe5>
		else if ('A' <= c && c <= 'Z')
f0100492:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100495:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100498:	83 f8 19             	cmp    $0x19,%eax
f010049b:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010049e:	f7 d2                	not    %edx
f01004a0:	f6 c2 06             	test   $0x6,%dl
f01004a3:	75 39                	jne    f01004de <kbd_proc_data+0x125>
f01004a5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004ab:	75 31                	jne    f01004de <kbd_proc_data+0x125>
		cprintf("Rebooting!\n");
f01004ad:	83 ec 0c             	sub    $0xc,%esp
f01004b0:	68 7c 43 10 f0       	push   $0xf010437c
f01004b5:	e8 15 2b 00 00       	call   f0102fcf <cprintf>
		outb(0x92, 0x3); // courtesy of Chris Frost
f01004ba:	ba 03 00 00 00       	mov    $0x3,%edx
f01004bf:	b8 92 00 00 00       	mov    $0x92,%eax
f01004c4:	e8 79 fc ff ff       	call   f0100142 <outb>
f01004c9:	83 c4 10             	add    $0x10,%esp
	}

	return c;
f01004cc:	89 d8                	mov    %ebx,%eax
f01004ce:	eb 10                	jmp    f01004e0 <kbd_proc_data+0x127>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004d5:	eb 09                	jmp    f01004e0 <kbd_proc_data+0x127>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01004dc:	eb 02                	jmp    f01004e0 <kbd_proc_data+0x127>
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01004de:	89 d8                	mov    %ebx,%eax
}
f01004e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01004e3:	c9                   	leave  
f01004e4:	c3                   	ret    

f01004e5 <cga_putc>:



static void
cga_putc(int c)
{
f01004e5:	55                   	push   %ebp
f01004e6:	89 e5                	mov    %esp,%ebp
f01004e8:	57                   	push   %edi
f01004e9:	56                   	push   %esi
f01004ea:	53                   	push   %ebx
f01004eb:	83 ec 0c             	sub    $0xc,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004ee:	89 c1                	mov    %eax,%ecx
f01004f0:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004f6:	89 c2                	mov    %eax,%edx
f01004f8:	80 ce 07             	or     $0x7,%dh
f01004fb:	85 c9                	test   %ecx,%ecx
f01004fd:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f0100500:	0f b6 d0             	movzbl %al,%edx
f0100503:	83 fa 09             	cmp    $0x9,%edx
f0100506:	74 72                	je     f010057a <cga_putc+0x95>
f0100508:	83 fa 09             	cmp    $0x9,%edx
f010050b:	7f 0a                	jg     f0100517 <cga_putc+0x32>
f010050d:	83 fa 08             	cmp    $0x8,%edx
f0100510:	74 14                	je     f0100526 <cga_putc+0x41>
f0100512:	e9 97 00 00 00       	jmp    f01005ae <cga_putc+0xc9>
f0100517:	83 fa 0a             	cmp    $0xa,%edx
f010051a:	74 38                	je     f0100554 <cga_putc+0x6f>
f010051c:	83 fa 0d             	cmp    $0xd,%edx
f010051f:	74 3b                	je     f010055c <cga_putc+0x77>
f0100521:	e9 88 00 00 00       	jmp    f01005ae <cga_putc+0xc9>
	case '\b':
		if (crt_pos > 0) {
f0100526:	0f b7 15 c8 4d 19 f0 	movzwl 0xf0194dc8,%edx
f010052d:	66 85 d2             	test   %dx,%dx
f0100530:	0f 84 e4 00 00 00    	je     f010061a <cga_putc+0x135>
			crt_pos--;
f0100536:	83 ea 01             	sub    $0x1,%edx
f0100539:	66 89 15 c8 4d 19 f0 	mov    %dx,0xf0194dc8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100540:	0f b7 d2             	movzwl %dx,%edx
f0100543:	b0 00                	mov    $0x0,%al
f0100545:	83 c8 20             	or     $0x20,%eax
f0100548:	8b 0d cc 4d 19 f0    	mov    0xf0194dcc,%ecx
f010054e:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100552:	eb 78                	jmp    f01005cc <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100554:	66 83 05 c8 4d 19 f0 	addw   $0x50,0xf0194dc8
f010055b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010055c:	0f b7 05 c8 4d 19 f0 	movzwl 0xf0194dc8,%eax
f0100563:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100569:	c1 e8 16             	shr    $0x16,%eax
f010056c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010056f:	c1 e0 04             	shl    $0x4,%eax
f0100572:	66 a3 c8 4d 19 f0    	mov    %ax,0xf0194dc8
		break;
f0100578:	eb 52                	jmp    f01005cc <cga_putc+0xe7>
	case '\t':
		cons_putc(' ');
f010057a:	b8 20 00 00 00       	mov    $0x20,%eax
f010057f:	e8 da 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f0100584:	b8 20 00 00 00       	mov    $0x20,%eax
f0100589:	e8 d0 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f010058e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100593:	e8 c6 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f0100598:	b8 20 00 00 00       	mov    $0x20,%eax
f010059d:	e8 bc 00 00 00       	call   f010065e <cons_putc>
		cons_putc(' ');
f01005a2:	b8 20 00 00 00       	mov    $0x20,%eax
f01005a7:	e8 b2 00 00 00       	call   f010065e <cons_putc>
		break;
f01005ac:	eb 1e                	jmp    f01005cc <cga_putc+0xe7>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005ae:	0f b7 15 c8 4d 19 f0 	movzwl 0xf0194dc8,%edx
f01005b5:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005b8:	66 89 0d c8 4d 19 f0 	mov    %cx,0xf0194dc8
f01005bf:	0f b7 d2             	movzwl %dx,%edx
f01005c2:	8b 0d cc 4d 19 f0    	mov    0xf0194dcc,%ecx
f01005c8:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005cc:	66 81 3d c8 4d 19 f0 	cmpw   $0x7cf,0xf0194dc8
f01005d3:	cf 07 
f01005d5:	76 43                	jbe    f010061a <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d7:	a1 cc 4d 19 f0       	mov    0xf0194dcc,%eax
f01005dc:	83 ec 04             	sub    $0x4,%esp
f01005df:	68 00 0f 00 00       	push   $0xf00
f01005e4:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005ea:	52                   	push   %edx
f01005eb:	50                   	push   %eax
f01005ec:	e8 e0 38 00 00       	call   f0103ed1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f1:	8b 15 cc 4d 19 f0    	mov    0xf0194dcc,%edx
f01005f7:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005fd:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100603:	83 c4 10             	add    $0x10,%esp
f0100606:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010060b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010060e:	39 d0                	cmp    %edx,%eax
f0100610:	75 f4                	jne    f0100606 <cga_putc+0x121>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100612:	66 83 2d c8 4d 19 f0 	subw   $0x50,0xf0194dc8
f0100619:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010061a:	8b 3d d0 4d 19 f0    	mov    0xf0194dd0,%edi
f0100620:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100625:	89 f8                	mov    %edi,%eax
f0100627:	e8 16 fb ff ff       	call   f0100142 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010062c:	0f b7 1d c8 4d 19 f0 	movzwl 0xf0194dc8,%ebx
f0100633:	8d 77 01             	lea    0x1(%edi),%esi
f0100636:	0f b6 d7             	movzbl %bh,%edx
f0100639:	89 f0                	mov    %esi,%eax
f010063b:	e8 02 fb ff ff       	call   f0100142 <outb>
	outb(addr_6845, 15);
f0100640:	ba 0f 00 00 00       	mov    $0xf,%edx
f0100645:	89 f8                	mov    %edi,%eax
f0100647:	e8 f6 fa ff ff       	call   f0100142 <outb>
	outb(addr_6845 + 1, crt_pos);
f010064c:	0f b6 d3             	movzbl %bl,%edx
f010064f:	89 f0                	mov    %esi,%eax
f0100651:	e8 ec fa ff ff       	call   f0100142 <outb>
}
f0100656:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100659:	5b                   	pop    %ebx
f010065a:	5e                   	pop    %esi
f010065b:	5f                   	pop    %edi
f010065c:	5d                   	pop    %ebp
f010065d:	c3                   	ret    

f010065e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010065e:	55                   	push   %ebp
f010065f:	89 e5                	mov    %esp,%ebp
f0100661:	53                   	push   %ebx
f0100662:	83 ec 04             	sub    $0x4,%esp
f0100665:	89 c3                	mov    %eax,%ebx
	serial_putc(c);
f0100667:	e8 36 fb ff ff       	call   f01001a2 <serial_putc>
	lpt_putc(c);
f010066c:	89 d8                	mov    %ebx,%eax
f010066e:	e8 03 fc ff ff       	call   f0100276 <lpt_putc>
	cga_putc(c);
f0100673:	89 d8                	mov    %ebx,%eax
f0100675:	e8 6b fe ff ff       	call   f01004e5 <cga_putc>
}
f010067a:	83 c4 04             	add    $0x4,%esp
f010067d:	5b                   	pop    %ebx
f010067e:	5d                   	pop    %ebp
f010067f:	c3                   	ret    

f0100680 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100680:	80 3d d4 4d 19 f0 00 	cmpb   $0x0,0xf0194dd4
f0100687:	74 11                	je     f010069a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100689:	55                   	push   %ebp
f010068a:	89 e5                	mov    %esp,%ebp
f010068c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010068f:	b8 7b 01 10 f0       	mov    $0xf010017b,%eax
f0100694:	e8 dd fc ff ff       	call   f0100376 <cons_intr>
}
f0100699:	c9                   	leave  
f010069a:	f3 c3                	repz ret 

f010069c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010069c:	55                   	push   %ebp
f010069d:	89 e5                	mov    %esp,%ebp
f010069f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01006a2:	b8 b9 03 10 f0       	mov    $0xf01003b9,%eax
f01006a7:	e8 ca fc ff ff       	call   f0100376 <cons_intr>
}
f01006ac:	c9                   	leave  
f01006ad:	c3                   	ret    

f01006ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01006ae:	55                   	push   %ebp
f01006af:	89 e5                	mov    %esp,%ebp
f01006b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01006b4:	e8 c7 ff ff ff       	call   f0100680 <serial_intr>
	kbd_intr();
f01006b9:	e8 de ff ff ff       	call   f010069c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01006be:	a1 c0 4d 19 f0       	mov    0xf0194dc0,%eax
f01006c3:	3b 05 c4 4d 19 f0    	cmp    0xf0194dc4,%eax
f01006c9:	74 26                	je     f01006f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006cb:	8d 50 01             	lea    0x1(%eax),%edx
f01006ce:	89 15 c0 4d 19 f0    	mov    %edx,0xf0194dc0
f01006d4:	0f b6 88 c0 4b 19 f0 	movzbl -0xfe6b440(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01006db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01006dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01006e3:	75 11                	jne    f01006f6 <cons_getc+0x48>
			cons.rpos = 0;
f01006e5:	c7 05 c0 4d 19 f0 00 	movl   $0x0,0xf0194dc0
f01006ec:	00 00 00 
f01006ef:	eb 05                	jmp    f01006f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01006f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01006f6:	c9                   	leave  
f01006f7:	c3                   	ret    

f01006f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01006f8:	55                   	push   %ebp
f01006f9:	89 e5                	mov    %esp,%ebp
f01006fb:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f01006fe:	e8 d0 fb ff ff       	call   f01002d3 <cga_init>
	kbd_init();
	serial_init();
f0100703:	e8 d9 fa ff ff       	call   f01001e1 <serial_init>

	if (!serial_exists)
f0100708:	80 3d d4 4d 19 f0 00 	cmpb   $0x0,0xf0194dd4
f010070f:	75 10                	jne    f0100721 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f0100711:	83 ec 0c             	sub    $0xc,%esp
f0100714:	68 88 43 10 f0       	push   $0xf0104388
f0100719:	e8 b1 28 00 00       	call   f0102fcf <cprintf>
f010071e:	83 c4 10             	add    $0x10,%esp
}
f0100721:	c9                   	leave  
f0100722:	c3                   	ret    

f0100723 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100723:	55                   	push   %ebp
f0100724:	89 e5                	mov    %esp,%ebp
f0100726:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100729:	8b 45 08             	mov    0x8(%ebp),%eax
f010072c:	e8 2d ff ff ff       	call   f010065e <cons_putc>
}
f0100731:	c9                   	leave  
f0100732:	c3                   	ret    

f0100733 <getchar>:

int
getchar(void)
{
f0100733:	55                   	push   %ebp
f0100734:	89 e5                	mov    %esp,%ebp
f0100736:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100739:	e8 70 ff ff ff       	call   f01006ae <cons_getc>
f010073e:	85 c0                	test   %eax,%eax
f0100740:	74 f7                	je     f0100739 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100742:	c9                   	leave  
f0100743:	c3                   	ret    

f0100744 <iscons>:

int
iscons(int fdnum)
{
f0100744:	55                   	push   %ebp
f0100745:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100747:	b8 01 00 00 00       	mov    $0x1,%eax
f010074c:	5d                   	pop    %ebp
f010074d:	c3                   	ret    

f010074e <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074e:	55                   	push   %ebp
f010074f:	89 e5                	mov    %esp,%ebp
f0100751:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100754:	68 e0 45 10 f0       	push   $0xf01045e0
f0100759:	68 fe 45 10 f0       	push   $0xf01045fe
f010075e:	68 03 46 10 f0       	push   $0xf0104603
f0100763:	e8 67 28 00 00       	call   f0102fcf <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	68 a0 46 10 f0       	push   $0xf01046a0
f0100770:	68 0c 46 10 f0       	push   $0xf010460c
f0100775:	68 03 46 10 f0       	push   $0xf0104603
f010077a:	e8 50 28 00 00       	call   f0102fcf <cprintf>
f010077f:	83 c4 0c             	add    $0xc,%esp
f0100782:	68 15 46 10 f0       	push   $0xf0104615
f0100787:	68 29 46 10 f0       	push   $0xf0104629
f010078c:	68 03 46 10 f0       	push   $0xf0104603
f0100791:	e8 39 28 00 00       	call   f0102fcf <cprintf>
	return 0;
}
f0100796:	b8 00 00 00 00       	mov    $0x0,%eax
f010079b:	c9                   	leave  
f010079c:	c3                   	ret    

f010079d <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010079d:	55                   	push   %ebp
f010079e:	89 e5                	mov    %esp,%ebp
f01007a0:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007a3:	68 33 46 10 f0       	push   $0xf0104633
f01007a8:	e8 22 28 00 00       	call   f0102fcf <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ad:	83 c4 08             	add    $0x8,%esp
f01007b0:	68 0c 00 10 00       	push   $0x10000c
f01007b5:	68 c8 46 10 f0       	push   $0xf01046c8
f01007ba:	e8 10 28 00 00       	call   f0102fcf <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 0c 00 10 00       	push   $0x10000c
f01007c7:	68 0c 00 10 f0       	push   $0xf010000c
f01007cc:	68 f0 46 10 f0       	push   $0xf01046f0
f01007d1:	e8 f9 27 00 00       	call   f0102fcf <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 11 43 10 00       	push   $0x104311
f01007de:	68 11 43 10 f0       	push   $0xf0104311
f01007e3:	68 14 47 10 f0       	push   $0xf0104714
f01007e8:	e8 e2 27 00 00       	call   f0102fcf <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007ed:	83 c4 0c             	add    $0xc,%esp
f01007f0:	68 9e 4b 19 00       	push   $0x194b9e
f01007f5:	68 9e 4b 19 f0       	push   $0xf0194b9e
f01007fa:	68 38 47 10 f0       	push   $0xf0104738
f01007ff:	e8 cb 27 00 00       	call   f0102fcf <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100804:	83 c4 0c             	add    $0xc,%esp
f0100807:	68 b0 6a 19 00       	push   $0x196ab0
f010080c:	68 b0 6a 19 f0       	push   $0xf0196ab0
f0100811:	68 5c 47 10 f0       	push   $0xf010475c
f0100816:	e8 b4 27 00 00       	call   f0102fcf <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010081b:	b8 af 6e 19 f0       	mov    $0xf0196eaf,%eax
f0100820:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100825:	83 c4 08             	add    $0x8,%esp
f0100828:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010082d:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100833:	85 c0                	test   %eax,%eax
f0100835:	0f 48 c2             	cmovs  %edx,%eax
f0100838:	c1 f8 0a             	sar    $0xa,%eax
f010083b:	50                   	push   %eax
f010083c:	68 80 47 10 f0       	push   $0xf0104780
f0100841:	e8 89 27 00 00       	call   f0102fcf <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100846:	b8 00 00 00 00       	mov    $0x0,%eax
f010084b:	c9                   	leave  
f010084c:	c3                   	ret    

f010084d <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010084d:	55                   	push   %ebp
f010084e:	89 e5                	mov    %esp,%ebp
f0100850:	57                   	push   %edi
f0100851:	56                   	push   %esi
f0100852:	53                   	push   %ebx
f0100853:	83 ec 2c             	sub    $0x2c,%esp

static inline uint32_t __attribute__((always_inline))
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100856:	89 eb                	mov    %ebp,%ebx
	while (ebp != 0x0){
	uint32_t eip=*(uint32_t *)(ebp+4);
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f0100858:	8d 7d d0             	lea    -0x30(%ebp),%edi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f010085b:	eb 4a                	jmp    f01008a7 <mon_backtrace+0x5a>
	uint32_t eip=*(uint32_t *)(ebp+4);
f010085d:	8b 73 04             	mov    0x4(%ebx),%esi
	cprintf("  ebp %08x eip %08x args %08x %08x %08x %08x %08x\n", ebp, eip, 
f0100860:	ff 73 18             	pushl  0x18(%ebx)
f0100863:	ff 73 14             	pushl  0x14(%ebx)
f0100866:	ff 73 10             	pushl  0x10(%ebx)
f0100869:	ff 73 0c             	pushl  0xc(%ebx)
f010086c:	ff 73 08             	pushl  0x8(%ebx)
f010086f:	56                   	push   %esi
f0100870:	53                   	push   %ebx
f0100871:	68 ac 47 10 f0       	push   $0xf01047ac
f0100876:	e8 54 27 00 00       	call   f0102fcf <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010087b:	83 c4 18             	add    $0x18,%esp
f010087e:	57                   	push   %edi
f010087f:	56                   	push   %esi
f0100880:	e8 43 2c 00 00       	call   f01034c8 <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100885:	83 c4 08             	add    $0x8,%esp
f0100888:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010088b:	56                   	push   %esi
f010088c:	ff 75 d8             	pushl  -0x28(%ebp)
f010088f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100892:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100895:	ff 75 d0             	pushl  -0x30(%ebp)
f0100898:	68 4c 46 10 f0       	push   $0xf010464c
f010089d:	e8 2d 27 00 00       	call   f0102fcf <cprintf>
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
f01008a2:	8b 1b                	mov    (%ebx),%ebx
f01008a4:	83 c4 20             	add    $0x20,%esp
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp();
	struct Eipdebuginfo dbgi;
	while (ebp != 0x0){
f01008a7:	85 db                	test   %ebx,%ebx
f01008a9:	75 b2                	jne    f010085d <mon_backtrace+0x10>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
			dbgi.eip_fn_name,((uintptr_t)eip - dbgi.eip_fn_addr));
	ebp = *(uint32_t *)(ebp);
	}
	return 0;
}
f01008ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01008b0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008b3:	5b                   	pop    %ebx
f01008b4:	5e                   	pop    %esi
f01008b5:	5f                   	pop    %edi
f01008b6:	5d                   	pop    %ebp
f01008b7:	c3                   	ret    

f01008b8 <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f01008b8:	55                   	push   %ebp
f01008b9:	89 e5                	mov    %esp,%ebp
f01008bb:	57                   	push   %edi
f01008bc:	56                   	push   %esi
f01008bd:	53                   	push   %ebx
f01008be:	83 ec 5c             	sub    $0x5c,%esp
f01008c1:	89 c3                	mov    %eax,%ebx
f01008c3:	89 55 a4             	mov    %edx,-0x5c(%ebp)
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008c6:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008cd:	be 00 00 00 00       	mov    $0x0,%esi
f01008d2:	eb 0a                	jmp    f01008de <runcmd+0x26>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d4:	c6 03 00             	movb   $0x0,(%ebx)
f01008d7:	89 f7                	mov    %esi,%edi
f01008d9:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008dc:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008de:	0f b6 03             	movzbl (%ebx),%eax
f01008e1:	84 c0                	test   %al,%al
f01008e3:	74 6d                	je     f0100952 <runcmd+0x9a>
f01008e5:	83 ec 08             	sub    $0x8,%esp
f01008e8:	0f be c0             	movsbl %al,%eax
f01008eb:	50                   	push   %eax
f01008ec:	68 63 46 10 f0       	push   $0xf0104663
f01008f1:	e8 50 35 00 00       	call   f0103e46 <strchr>
f01008f6:	83 c4 10             	add    $0x10,%esp
f01008f9:	85 c0                	test   %eax,%eax
f01008fb:	75 d7                	jne    f01008d4 <runcmd+0x1c>
			*buf++ = 0;
		if (*buf == 0)
f01008fd:	0f b6 03             	movzbl (%ebx),%eax
f0100900:	84 c0                	test   %al,%al
f0100902:	74 4e                	je     f0100952 <runcmd+0x9a>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100904:	83 fe 0f             	cmp    $0xf,%esi
f0100907:	75 1c                	jne    f0100925 <runcmd+0x6d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100909:	83 ec 08             	sub    $0x8,%esp
f010090c:	6a 10                	push   $0x10
f010090e:	68 68 46 10 f0       	push   $0xf0104668
f0100913:	e8 b7 26 00 00       	call   f0102fcf <cprintf>
			return 0;
f0100918:	83 c4 10             	add    $0x10,%esp
f010091b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100920:	e9 99 00 00 00       	jmp    f01009be <runcmd+0x106>
		}
		argv[argc++] = buf;
f0100925:	8d 7e 01             	lea    0x1(%esi),%edi
f0100928:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010092c:	eb 0a                	jmp    f0100938 <runcmd+0x80>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010092e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100931:	0f b6 03             	movzbl (%ebx),%eax
f0100934:	84 c0                	test   %al,%al
f0100936:	74 a4                	je     f01008dc <runcmd+0x24>
f0100938:	83 ec 08             	sub    $0x8,%esp
f010093b:	0f be c0             	movsbl %al,%eax
f010093e:	50                   	push   %eax
f010093f:	68 63 46 10 f0       	push   $0xf0104663
f0100944:	e8 fd 34 00 00       	call   f0103e46 <strchr>
f0100949:	83 c4 10             	add    $0x10,%esp
f010094c:	85 c0                	test   %eax,%eax
f010094e:	74 de                	je     f010092e <runcmd+0x76>
f0100950:	eb 8a                	jmp    f01008dc <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f0100952:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100959:	00 

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
f010095a:	b8 00 00 00 00       	mov    $0x0,%eax
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
f010095f:	85 f6                	test   %esi,%esi
f0100961:	74 5b                	je     f01009be <runcmd+0x106>
f0100963:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100968:	83 ec 08             	sub    $0x8,%esp
f010096b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010096e:	ff 34 85 40 48 10 f0 	pushl  -0xfefb7c0(,%eax,4)
f0100975:	ff 75 a8             	pushl  -0x58(%ebp)
f0100978:	e8 6b 34 00 00       	call   f0103de8 <strcmp>
f010097d:	83 c4 10             	add    $0x10,%esp
f0100980:	85 c0                	test   %eax,%eax
f0100982:	75 1a                	jne    f010099e <runcmd+0xe6>
			return commands[i].func(argc, argv, tf);
f0100984:	83 ec 04             	sub    $0x4,%esp
f0100987:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010098a:	ff 75 a4             	pushl  -0x5c(%ebp)
f010098d:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100990:	52                   	push   %edx
f0100991:	56                   	push   %esi
f0100992:	ff 14 85 48 48 10 f0 	call   *-0xfefb7b8(,%eax,4)
f0100999:	83 c4 10             	add    $0x10,%esp
f010099c:	eb 20                	jmp    f01009be <runcmd+0x106>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010099e:	83 c3 01             	add    $0x1,%ebx
f01009a1:	83 fb 03             	cmp    $0x3,%ebx
f01009a4:	75 c2                	jne    f0100968 <runcmd+0xb0>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009a6:	83 ec 08             	sub    $0x8,%esp
f01009a9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ac:	68 85 46 10 f0       	push   $0xf0104685
f01009b1:	e8 19 26 00 00       	call   f0102fcf <cprintf>
	return 0;
f01009b6:	83 c4 10             	add    $0x10,%esp
f01009b9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009c1:	5b                   	pop    %ebx
f01009c2:	5e                   	pop    %esi
f01009c3:	5f                   	pop    %edi
f01009c4:	5d                   	pop    %ebp
f01009c5:	c3                   	ret    

f01009c6 <monitor>:

void
monitor(struct Trapframe *tf)
{
f01009c6:	55                   	push   %ebp
f01009c7:	89 e5                	mov    %esp,%ebp
f01009c9:	53                   	push   %ebx
f01009ca:	83 ec 10             	sub    $0x10,%esp
f01009cd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009d0:	68 e0 47 10 f0       	push   $0xf01047e0
f01009d5:	e8 f5 25 00 00       	call   f0102fcf <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009da:	c7 04 24 04 48 10 f0 	movl   $0xf0104804,(%esp)
f01009e1:	e8 e9 25 00 00       	call   f0102fcf <cprintf>

	if (tf != NULL)
f01009e6:	83 c4 10             	add    $0x10,%esp
f01009e9:	85 db                	test   %ebx,%ebx
f01009eb:	74 0c                	je     f01009f9 <monitor+0x33>
		print_trapframe(tf);
f01009ed:	83 ec 0c             	sub    $0xc,%esp
f01009f0:	53                   	push   %ebx
f01009f1:	e8 28 27 00 00       	call   f010311e <print_trapframe>
f01009f6:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009f9:	83 ec 0c             	sub    $0xc,%esp
f01009fc:	68 9b 46 10 f0       	push   $0xf010469b
f0100a01:	e8 26 32 00 00       	call   f0103c2c <readline>
		if (buf != NULL)
f0100a06:	83 c4 10             	add    $0x10,%esp
f0100a09:	85 c0                	test   %eax,%eax
f0100a0b:	74 ec                	je     f01009f9 <monitor+0x33>
			if (runcmd(buf, tf) < 0)
f0100a0d:	89 da                	mov    %ebx,%edx
f0100a0f:	e8 a4 fe ff ff       	call   f01008b8 <runcmd>
f0100a14:	85 c0                	test   %eax,%eax
f0100a16:	79 e1                	jns    f01009f9 <monitor+0x33>
				break;
	}
}
f0100a18:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a1b:	c9                   	leave  
f0100a1c:	c3                   	ret    

f0100a1d <invlpg>:
	asm volatile("outl %0,%w1" : : "a" (data), "d" (port));
}

static inline void
invlpg(void *addr)
{
f0100a1d:	55                   	push   %ebp
f0100a1e:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100a20:	0f 01 38             	invlpg (%eax)
}
f0100a23:	5d                   	pop    %ebp
f0100a24:	c3                   	ret    

f0100a25 <lcr0>:
	asm volatile("ltr %0" : : "r" (sel));
}

static inline void
lcr0(uint32_t val)
{
f0100a25:	55                   	push   %ebp
f0100a26:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0100a28:	0f 22 c0             	mov    %eax,%cr0
}
f0100a2b:	5d                   	pop    %ebp
f0100a2c:	c3                   	ret    

f0100a2d <rcr0>:

static inline uint32_t
rcr0(void)
{
f0100a2d:	55                   	push   %ebp
f0100a2e:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0100a30:	0f 20 c0             	mov    %cr0,%eax
	return val;
}
f0100a33:	5d                   	pop    %ebp
f0100a34:	c3                   	ret    

f0100a35 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0100a35:	55                   	push   %ebp
f0100a36:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0100a38:	0f 22 d8             	mov    %eax,%cr3
}
f0100a3b:	5d                   	pop    %ebp
f0100a3c:	c3                   	ret    

f0100a3d <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0100a3d:	55                   	push   %ebp
f0100a3e:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0100a40:	2b 05 ac 6a 19 f0    	sub    0xf0196aac,%eax
f0100a46:	c1 f8 03             	sar    $0x3,%eax
f0100a49:	c1 e0 0c             	shl    $0xc,%eax
}
f0100a4c:	5d                   	pop    %ebp
f0100a4d:	c3                   	ret    

f0100a4e <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a4e:	55                   	push   %ebp
f0100a4f:	89 e5                	mov    %esp,%ebp
f0100a51:	56                   	push   %esi
f0100a52:	53                   	push   %ebx
f0100a53:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a55:	83 ec 0c             	sub    $0xc,%esp
f0100a58:	50                   	push   %eax
f0100a59:	e8 f7 24 00 00       	call   f0102f55 <mc146818_read>
f0100a5e:	89 c6                	mov    %eax,%esi
f0100a60:	83 c3 01             	add    $0x1,%ebx
f0100a63:	89 1c 24             	mov    %ebx,(%esp)
f0100a66:	e8 ea 24 00 00       	call   f0102f55 <mc146818_read>
f0100a6b:	c1 e0 08             	shl    $0x8,%eax
f0100a6e:	09 f0                	or     %esi,%eax
}
f0100a70:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100a73:	5b                   	pop    %ebx
f0100a74:	5e                   	pop    %esi
f0100a75:	5d                   	pop    %ebp
f0100a76:	c3                   	ret    

f0100a77 <i386_detect_memory>:

static void
i386_detect_memory(void)
{
f0100a77:	55                   	push   %ebp
f0100a78:	89 e5                	mov    %esp,%ebp
f0100a7a:	56                   	push   %esi
f0100a7b:	53                   	push   %ebx
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100a7c:	b8 15 00 00 00       	mov    $0x15,%eax
f0100a81:	e8 c8 ff ff ff       	call   f0100a4e <nvram_read>
f0100a86:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100a88:	b8 17 00 00 00       	mov    $0x17,%eax
f0100a8d:	e8 bc ff ff ff       	call   f0100a4e <nvram_read>
f0100a92:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100a94:	b8 34 00 00 00       	mov    $0x34,%eax
f0100a99:	e8 b0 ff ff ff       	call   f0100a4e <nvram_read>
f0100a9e:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100aa1:	85 c0                	test   %eax,%eax
f0100aa3:	74 07                	je     f0100aac <i386_detect_memory+0x35>
		totalmem = 16 * 1024 + ext16mem;
f0100aa5:	05 00 40 00 00       	add    $0x4000,%eax
f0100aaa:	eb 0b                	jmp    f0100ab7 <i386_detect_memory+0x40>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100aac:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100ab2:	85 f6                	test   %esi,%esi
f0100ab4:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100ab7:	89 c2                	mov    %eax,%edx
f0100ab9:	c1 ea 02             	shr    $0x2,%edx
f0100abc:	89 15 a4 6a 19 f0    	mov    %edx,0xf0196aa4
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ac2:	89 c2                	mov    %eax,%edx
f0100ac4:	29 da                	sub    %ebx,%edx
f0100ac6:	52                   	push   %edx
f0100ac7:	53                   	push   %ebx
f0100ac8:	50                   	push   %eax
f0100ac9:	68 64 48 10 f0       	push   $0xf0104864
f0100ace:	e8 fc 24 00 00       	call   f0102fcf <cprintf>
		totalmem, basemem, totalmem - basemem);
}
f0100ad3:	83 c4 10             	add    $0x10,%esp
f0100ad6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ad9:	5b                   	pop    %ebx
f0100ada:	5e                   	pop    %esi
f0100adb:	5d                   	pop    %ebp
f0100adc:	c3                   	ret    

f0100add <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0100add:	55                   	push   %ebp
f0100ade:	89 e5                	mov    %esp,%ebp
f0100ae0:	53                   	push   %ebx
f0100ae1:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f0100ae4:	89 cb                	mov    %ecx,%ebx
f0100ae6:	c1 eb 0c             	shr    $0xc,%ebx
f0100ae9:	3b 1d a4 6a 19 f0    	cmp    0xf0196aa4,%ebx
f0100aef:	72 0d                	jb     f0100afe <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af1:	51                   	push   %ecx
f0100af2:	68 a0 48 10 f0       	push   $0xf01048a0
f0100af7:	52                   	push   %edx
f0100af8:	50                   	push   %eax
f0100af9:	e8 ab f5 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f0100afe:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0100b04:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b07:	c9                   	leave  
f0100b08:	c3                   	ret    

f0100b09 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b09:	55                   	push   %ebp
f0100b0a:	89 e5                	mov    %esp,%ebp
f0100b0c:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f0100b0f:	e8 29 ff ff ff       	call   f0100a3d <page2pa>
f0100b14:	89 c1                	mov    %eax,%ecx
f0100b16:	ba 56 00 00 00       	mov    $0x56,%edx
f0100b1b:	b8 4d 50 10 f0       	mov    $0xf010504d,%eax
f0100b20:	e8 b8 ff ff ff       	call   f0100add <_kaddr>
}
f0100b25:	c9                   	leave  
f0100b26:	c3                   	ret    

f0100b27 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100b27:	89 d1                	mov    %edx,%ecx
f0100b29:	c1 e9 16             	shr    $0x16,%ecx
f0100b2c:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
f0100b2f:	f6 c1 01             	test   $0x1,%cl
f0100b32:	74 57                	je     f0100b8b <check_va2pa+0x64>
		return ~0;
	if (*pgdir & PTE_PS)
f0100b34:	f6 c1 80             	test   $0x80,%cl
f0100b37:	74 10                	je     f0100b49 <check_va2pa+0x22>
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
f0100b39:	89 d0                	mov    %edx,%eax
f0100b3b:	25 ff ff 3f 00       	and    $0x3fffff,%eax
f0100b40:	81 e1 00 00 c0 ff    	and    $0xffc00000,%ecx
f0100b46:	09 c8                	or     %ecx,%eax
f0100b48:	c3                   	ret    
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b49:	55                   	push   %ebp
f0100b4a:	89 e5                	mov    %esp,%ebp
f0100b4c:	53                   	push   %ebx
f0100b4d:	83 ec 04             	sub    $0x4,%esp
f0100b50:	89 d3                	mov    %edx,%ebx
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	if (*pgdir & PTE_PS)
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b52:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100b58:	ba 1b 03 00 00       	mov    $0x31b,%edx
f0100b5d:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0100b62:	e8 76 ff ff ff       	call   f0100add <_kaddr>
	if (!(p[PTX(va)] & PTE_P))
f0100b67:	c1 eb 0c             	shr    $0xc,%ebx
f0100b6a:	89 da                	mov    %ebx,%edx
f0100b6c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b72:	8b 04 90             	mov    (%eax,%edx,4),%eax
f0100b75:	89 c2                	mov    %eax,%edx
f0100b77:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b7a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b7f:	85 d2                	test   %edx,%edx
f0100b81:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
f0100b86:	0f 44 c1             	cmove  %ecx,%eax
f0100b89:	eb 06                	jmp    f0100b91 <check_va2pa+0x6a>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b90:	c3                   	ret    
		return (physaddr_t) PGADDR(PDX(*pgdir), PTX(va), PGOFF(va));
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b91:	83 c4 04             	add    $0x4,%esp
f0100b94:	5b                   	pop    %ebx
f0100b95:	5d                   	pop    %ebp
f0100b96:	c3                   	ret    

f0100b97 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100b97:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0100b9d:	77 13                	ja     f0100bb2 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f0100b9f:	55                   	push   %ebp
f0100ba0:	89 e5                	mov    %esp,%ebp
f0100ba2:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100ba5:	51                   	push   %ecx
f0100ba6:	68 c4 48 10 f0       	push   $0xf01048c4
f0100bab:	52                   	push   %edx
f0100bac:	50                   	push   %eax
f0100bad:	e8 f7 f4 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100bb2:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0100bb8:	c3                   	ret    

f0100bb9 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100bb9:	83 3d d8 4d 19 f0 00 	cmpl   $0x0,0xf0194dd8
f0100bc0:	75 11                	jne    f0100bd3 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100bc2:	ba af 7a 19 f0       	mov    $0xf0197aaf,%edx
f0100bc7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bcd:	89 15 d8 4d 19 f0    	mov    %edx,0xf0194dd8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100bd3:	85 c0                	test   %eax,%eax
f0100bd5:	75 06                	jne    f0100bdd <boot_alloc+0x24>
f0100bd7:	a1 d8 4d 19 f0       	mov    0xf0194dd8,%eax
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
	return (void*) result;
}
f0100bdc:	c3                   	ret    
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bdd:	55                   	push   %ebp
f0100bde:	89 e5                	mov    %esp,%ebp
f0100be0:	53                   	push   %ebx
f0100be1:	83 ec 04             	sub    $0x4,%esp
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
	//n>0 (n<0 no deberia ocurrir por precond)
	result = nextfree;
f0100be4:	8b 1d d8 4d 19 f0    	mov    0xf0194dd8,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100bea:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100bf0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100bf6:	01 d9                	add    %ebx,%ecx
f0100bf8:	89 0d d8 4d 19 f0    	mov    %ecx,0xf0194dd8
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100bfe:	ba 6e 00 00 00       	mov    $0x6e,%edx
f0100c03:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0100c08:	e8 8a ff ff ff       	call   f0100b97 <_paddr>
f0100c0d:	8b 15 a4 6a 19 f0    	mov    0xf0196aa4,%edx
f0100c13:	c1 e2 0c             	shl    $0xc,%edx
f0100c16:	39 d0                	cmp    %edx,%eax
f0100c18:	76 14                	jbe    f0100c2e <boot_alloc+0x75>
f0100c1a:	83 ec 04             	sub    $0x4,%esp
f0100c1d:	68 67 50 10 f0       	push   $0xf0105067
f0100c22:	6a 6e                	push   $0x6e
f0100c24:	68 5b 50 10 f0       	push   $0xf010505b
f0100c29:	e8 7b f4 ff ff       	call   f01000a9 <_panic>
	return (void*) result;
f0100c2e:	89 d8                	mov    %ebx,%eax
}
f0100c30:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100c33:	c9                   	leave  
f0100c34:	c3                   	ret    

f0100c35 <check_kern_pgdir>:
// but it is a pretty good sanity check.
//

static void
check_kern_pgdir(void)
{
f0100c35:	55                   	push   %ebp
f0100c36:	89 e5                	mov    %esp,%ebp
f0100c38:	57                   	push   %edi
f0100c39:	56                   	push   %esi
f0100c3a:	53                   	push   %ebx
f0100c3b:	83 ec 1c             	sub    $0x1c,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0100c3e:	8b 1d a8 6a 19 f0    	mov    0xf0196aa8,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c44:	a1 a4 6a 19 f0       	mov    0xf0196aa4,%eax
f0100c49:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c4c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c5b:	a1 ac 6a 19 f0       	mov    0xf0196aac,%eax
f0100c60:	89 45 e0             	mov    %eax,-0x20(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100c63:	be 00 00 00 00       	mov    $0x0,%esi
f0100c68:	eb 46                	jmp    f0100cb0 <check_kern_pgdir+0x7b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c6a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
f0100c70:	89 d8                	mov    %ebx,%eax
f0100c72:	e8 b0 fe ff ff       	call   f0100b27 <check_va2pa>
f0100c77:	89 c7                	mov    %eax,%edi
f0100c79:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c7c:	ba dd 02 00 00       	mov    $0x2dd,%edx
f0100c81:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0100c86:	e8 0c ff ff ff       	call   f0100b97 <_paddr>
f0100c8b:	01 f0                	add    %esi,%eax
f0100c8d:	39 c7                	cmp    %eax,%edi
f0100c8f:	74 19                	je     f0100caa <check_kern_pgdir+0x75>
f0100c91:	68 e8 48 10 f0       	push   $0xf01048e8
f0100c96:	68 7a 50 10 f0       	push   $0xf010507a
f0100c9b:	68 dd 02 00 00       	push   $0x2dd
f0100ca0:	68 5b 50 10 f0       	push   $0xf010505b
f0100ca5:	e8 ff f3 ff ff       	call   f01000a9 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100caa:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100cb0:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100cb3:	72 b5                	jb     f0100c6a <check_kern_pgdir+0x35>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0100cb5:	a1 e4 4d 19 f0       	mov    0xf0194de4,%eax
f0100cba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cbd:	be 00 00 00 00       	mov    $0x0,%esi
f0100cc2:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
f0100cc8:	89 d8                	mov    %ebx,%eax
f0100cca:	e8 58 fe ff ff       	call   f0100b27 <check_va2pa>
f0100ccf:	89 c7                	mov    %eax,%edi
f0100cd1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100cd4:	ba e2 02 00 00       	mov    $0x2e2,%edx
f0100cd9:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0100cde:	e8 b4 fe ff ff       	call   f0100b97 <_paddr>
f0100ce3:	01 f0                	add    %esi,%eax
f0100ce5:	39 c7                	cmp    %eax,%edi
f0100ce7:	74 19                	je     f0100d02 <check_kern_pgdir+0xcd>
f0100ce9:	68 1c 49 10 f0       	push   $0xf010491c
f0100cee:	68 7a 50 10 f0       	push   $0xf010507a
f0100cf3:	68 e2 02 00 00       	push   $0x2e2
f0100cf8:	68 5b 50 10 f0       	push   $0xf010505b
f0100cfd:	e8 a7 f3 ff ff       	call   f01000a9 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0100d02:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d08:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0100d0e:	75 b2                	jne    f0100cc2 <check_kern_pgdir+0x8d>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100d10:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100d13:	c1 e7 0c             	shl    $0xc,%edi
f0100d16:	be 00 00 00 00       	mov    $0x0,%esi
f0100d1b:	eb 30                	jmp    f0100d4d <check_kern_pgdir+0x118>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0100d1d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
f0100d23:	89 d8                	mov    %ebx,%eax
f0100d25:	e8 fd fd ff ff       	call   f0100b27 <check_va2pa>
f0100d2a:	39 c6                	cmp    %eax,%esi
f0100d2c:	74 19                	je     f0100d47 <check_kern_pgdir+0x112>
f0100d2e:	68 50 49 10 f0       	push   $0xf0104950
f0100d33:	68 7a 50 10 f0       	push   $0xf010507a
f0100d38:	68 e6 02 00 00       	push   $0x2e6
f0100d3d:	68 5b 50 10 f0       	push   $0xf010505b
f0100d42:	e8 62 f3 ff ff       	call   f01000a9 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0100d47:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d4d:	39 fe                	cmp    %edi,%esi
f0100d4f:	72 cc                	jb     f0100d1d <check_kern_pgdir+0xe8>
f0100d51:	be 00 00 00 00       	mov    $0x0,%esi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0100d56:	8d 96 00 80 ff ef    	lea    -0x10008000(%esi),%edx
f0100d5c:	89 d8                	mov    %ebx,%eax
f0100d5e:	e8 c4 fd ff ff       	call   f0100b27 <check_va2pa>
f0100d63:	89 c7                	mov    %eax,%edi
f0100d65:	b9 00 60 10 f0       	mov    $0xf0106000,%ecx
f0100d6a:	ba ea 02 00 00       	mov    $0x2ea,%edx
f0100d6f:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0100d74:	e8 1e fe ff ff       	call   f0100b97 <_paddr>
f0100d79:	01 f0                	add    %esi,%eax
f0100d7b:	39 c7                	cmp    %eax,%edi
f0100d7d:	74 19                	je     f0100d98 <check_kern_pgdir+0x163>
f0100d7f:	68 78 49 10 f0       	push   $0xf0104978
f0100d84:	68 7a 50 10 f0       	push   $0xf010507a
f0100d89:	68 ea 02 00 00       	push   $0x2ea
f0100d8e:	68 5b 50 10 f0       	push   $0xf010505b
f0100d93:	e8 11 f3 ff ff       	call   f01000a9 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0100d98:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100d9e:	81 fe 00 80 00 00    	cmp    $0x8000,%esi
f0100da4:	75 b0                	jne    f0100d56 <check_kern_pgdir+0x121>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0100da6:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0100dab:	89 d8                	mov    %ebx,%eax
f0100dad:	e8 75 fd ff ff       	call   f0100b27 <check_va2pa>
f0100db2:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100db5:	74 51                	je     f0100e08 <check_kern_pgdir+0x1d3>
f0100db7:	68 c0 49 10 f0       	push   $0xf01049c0
f0100dbc:	68 7a 50 10 f0       	push   $0xf010507a
f0100dc1:	68 eb 02 00 00       	push   $0x2eb
f0100dc6:	68 5b 50 10 f0       	push   $0xf010505b
f0100dcb:	e8 d9 f2 ff ff       	call   f01000a9 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0100dd0:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0100dd5:	72 36                	jb     f0100e0d <check_kern_pgdir+0x1d8>
f0100dd7:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0100ddc:	76 07                	jbe    f0100de5 <check_kern_pgdir+0x1b0>
f0100dde:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100de3:	75 28                	jne    f0100e0d <check_kern_pgdir+0x1d8>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0100de5:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0100de9:	0f 85 83 00 00 00    	jne    f0100e72 <check_kern_pgdir+0x23d>
f0100def:	68 8f 50 10 f0       	push   $0xf010508f
f0100df4:	68 7a 50 10 f0       	push   $0xf010507a
f0100df9:	68 f4 02 00 00       	push   $0x2f4
f0100dfe:	68 5b 50 10 f0       	push   $0xf010505b
f0100e03:	e8 a1 f2 ff ff       	call   f01000a9 <_panic>
f0100e08:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0100e0d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0100e12:	76 3f                	jbe    f0100e53 <check_kern_pgdir+0x21e>
				assert(pgdir[i] & PTE_P);
f0100e14:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0100e17:	f6 c2 01             	test   $0x1,%dl
f0100e1a:	75 19                	jne    f0100e35 <check_kern_pgdir+0x200>
f0100e1c:	68 8f 50 10 f0       	push   $0xf010508f
f0100e21:	68 7a 50 10 f0       	push   $0xf010507a
f0100e26:	68 f8 02 00 00       	push   $0x2f8
f0100e2b:	68 5b 50 10 f0       	push   $0xf010505b
f0100e30:	e8 74 f2 ff ff       	call   f01000a9 <_panic>
				assert(pgdir[i] & PTE_W);
f0100e35:	f6 c2 02             	test   $0x2,%dl
f0100e38:	75 38                	jne    f0100e72 <check_kern_pgdir+0x23d>
f0100e3a:	68 a0 50 10 f0       	push   $0xf01050a0
f0100e3f:	68 7a 50 10 f0       	push   $0xf010507a
f0100e44:	68 f9 02 00 00       	push   $0x2f9
f0100e49:	68 5b 50 10 f0       	push   $0xf010505b
f0100e4e:	e8 56 f2 ff ff       	call   f01000a9 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100e53:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100e57:	74 19                	je     f0100e72 <check_kern_pgdir+0x23d>
f0100e59:	68 b1 50 10 f0       	push   $0xf01050b1
f0100e5e:	68 7a 50 10 f0       	push   $0xf010507a
f0100e63:	68 fb 02 00 00       	push   $0x2fb
f0100e68:	68 5b 50 10 f0       	push   $0xf010505b
f0100e6d:	e8 37 f2 ff ff       	call   f01000a9 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0100e72:	83 c0 01             	add    $0x1,%eax
f0100e75:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0100e7a:	0f 86 50 ff ff ff    	jbe    f0100dd0 <check_kern_pgdir+0x19b>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0100e80:	83 ec 0c             	sub    $0xc,%esp
f0100e83:	68 f0 49 10 f0       	push   $0xf01049f0
f0100e88:	e8 42 21 00 00       	call   f0102fcf <cprintf>
			assert(PTE_ADDR(pgdir[i]) == (i - kern_pdx) << PDXSHIFT);
		}
		cprintf("check_kern_pgdir_pse() succeeded!\n");
	#endif

}
f0100e8d:	83 c4 10             	add    $0x10,%esp
f0100e90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e93:	5b                   	pop    %ebx
f0100e94:	5e                   	pop    %esi
f0100e95:	5f                   	pop    %edi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	57                   	push   %edi
f0100e9c:	56                   	push   %esi
f0100e9d:	53                   	push   %ebx
f0100e9e:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ea1:	84 c0                	test   %al,%al
f0100ea3:	0f 85 35 02 00 00    	jne    f01010de <check_page_free_list+0x246>
f0100ea9:	e9 43 02 00 00       	jmp    f01010f1 <check_page_free_list+0x259>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100eae:	83 ec 04             	sub    $0x4,%esp
f0100eb1:	68 10 4a 10 f0       	push   $0xf0104a10
f0100eb6:	68 4d 02 00 00       	push   $0x24d
f0100ebb:	68 5b 50 10 f0       	push   $0xf010505b
f0100ec0:	e8 e4 f1 ff ff       	call   f01000a9 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ec5:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0100ec8:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ecb:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0100ece:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ed1:	89 d8                	mov    %ebx,%eax
f0100ed3:	e8 65 fb ff ff       	call   f0100a3d <page2pa>
f0100ed8:	c1 e8 16             	shr    $0x16,%eax
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	0f 95 c0             	setne  %al
f0100ee0:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100ee3:	8b 54 85 e0          	mov    -0x20(%ebp,%eax,4),%edx
f0100ee7:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100ee9:	89 5c 85 e0          	mov    %ebx,-0x20(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100eed:	8b 1b                	mov    (%ebx),%ebx
f0100eef:	85 db                	test   %ebx,%ebx
f0100ef1:	75 de                	jne    f0100ed1 <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ef3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ef6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100efc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100eff:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f02:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f04:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f07:	a3 dc 4d 19 f0       	mov    %eax,0xf0194ddc
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f0c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f11:	8b 1d dc 4d 19 f0    	mov    0xf0194ddc,%ebx
f0100f17:	eb 2d                	jmp    f0100f46 <check_page_free_list+0xae>
		if (PDX(page2pa(pp)) < pdx_limit)
f0100f19:	89 d8                	mov    %ebx,%eax
f0100f1b:	e8 1d fb ff ff       	call   f0100a3d <page2pa>
f0100f20:	c1 e8 16             	shr    $0x16,%eax
f0100f23:	39 f0                	cmp    %esi,%eax
f0100f25:	73 1d                	jae    f0100f44 <check_page_free_list+0xac>
			memset(page2kva(pp), 0x97, 128);
f0100f27:	89 d8                	mov    %ebx,%eax
f0100f29:	e8 db fb ff ff       	call   f0100b09 <page2kva>
f0100f2e:	83 ec 04             	sub    $0x4,%esp
f0100f31:	68 80 00 00 00       	push   $0x80
f0100f36:	68 97 00 00 00       	push   $0x97
f0100f3b:	50                   	push   %eax
f0100f3c:	e8 42 2f 00 00       	call   f0103e83 <memset>
f0100f41:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f44:	8b 1b                	mov    (%ebx),%ebx
f0100f46:	85 db                	test   %ebx,%ebx
f0100f48:	75 cf                	jne    f0100f19 <check_page_free_list+0x81>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100f4a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f4f:	e8 65 fc ff ff       	call   f0100bb9 <boot_alloc>
f0100f54:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f57:	8b 1d dc 4d 19 f0    	mov    0xf0194ddc,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f5d:	8b 35 ac 6a 19 f0    	mov    0xf0196aac,%esi
		assert(pp < pages + npages);
f0100f63:	a1 a4 6a 19 f0       	mov    0xf0196aa4,%eax
f0100f68:	8d 04 c6             	lea    (%esi,%eax,8),%eax
f0100f6b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100f6e:	89 75 d0             	mov    %esi,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100f71:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
f0100f78:	bf 00 00 00 00       	mov    $0x0,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f7d:	e9 18 01 00 00       	jmp    f010109a <check_page_free_list+0x202>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f82:	39 f3                	cmp    %esi,%ebx
f0100f84:	73 19                	jae    f0100f9f <check_page_free_list+0x107>
f0100f86:	68 bf 50 10 f0       	push   $0xf01050bf
f0100f8b:	68 7a 50 10 f0       	push   $0xf010507a
f0100f90:	68 67 02 00 00       	push   $0x267
f0100f95:	68 5b 50 10 f0       	push   $0xf010505b
f0100f9a:	e8 0a f1 ff ff       	call   f01000a9 <_panic>
		assert(pp < pages + npages);
f0100f9f:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100fa2:	72 19                	jb     f0100fbd <check_page_free_list+0x125>
f0100fa4:	68 cb 50 10 f0       	push   $0xf01050cb
f0100fa9:	68 7a 50 10 f0       	push   $0xf010507a
f0100fae:	68 68 02 00 00       	push   $0x268
f0100fb3:	68 5b 50 10 f0       	push   $0xf010505b
f0100fb8:	e8 ec f0 ff ff       	call   f01000a9 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100fbd:	89 d8                	mov    %ebx,%eax
f0100fbf:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100fc2:	a8 07                	test   $0x7,%al
f0100fc4:	74 19                	je     f0100fdf <check_page_free_list+0x147>
f0100fc6:	68 34 4a 10 f0       	push   $0xf0104a34
f0100fcb:	68 7a 50 10 f0       	push   $0xf010507a
f0100fd0:	68 69 02 00 00       	push   $0x269
f0100fd5:	68 5b 50 10 f0       	push   $0xf010505b
f0100fda:	e8 ca f0 ff ff       	call   f01000a9 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100fdf:	89 d8                	mov    %ebx,%eax
f0100fe1:	e8 57 fa ff ff       	call   f0100a3d <page2pa>
f0100fe6:	85 c0                	test   %eax,%eax
f0100fe8:	75 19                	jne    f0101003 <check_page_free_list+0x16b>
f0100fea:	68 df 50 10 f0       	push   $0xf01050df
f0100fef:	68 7a 50 10 f0       	push   $0xf010507a
f0100ff4:	68 6c 02 00 00       	push   $0x26c
f0100ff9:	68 5b 50 10 f0       	push   $0xf010505b
f0100ffe:	e8 a6 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101003:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101008:	75 19                	jne    f0101023 <check_page_free_list+0x18b>
f010100a:	68 f0 50 10 f0       	push   $0xf01050f0
f010100f:	68 7a 50 10 f0       	push   $0xf010507a
f0101014:	68 6d 02 00 00       	push   $0x26d
f0101019:	68 5b 50 10 f0       	push   $0xf010505b
f010101e:	e8 86 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101023:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101028:	75 19                	jne    f0101043 <check_page_free_list+0x1ab>
f010102a:	68 68 4a 10 f0       	push   $0xf0104a68
f010102f:	68 7a 50 10 f0       	push   $0xf010507a
f0101034:	68 6e 02 00 00       	push   $0x26e
f0101039:	68 5b 50 10 f0       	push   $0xf010505b
f010103e:	e8 66 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101043:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101048:	75 19                	jne    f0101063 <check_page_free_list+0x1cb>
f010104a:	68 09 51 10 f0       	push   $0xf0105109
f010104f:	68 7a 50 10 f0       	push   $0xf010507a
f0101054:	68 6f 02 00 00       	push   $0x26f
f0101059:	68 5b 50 10 f0       	push   $0xf010505b
f010105e:	e8 46 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101063:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101068:	76 25                	jbe    f010108f <check_page_free_list+0x1f7>
f010106a:	89 d8                	mov    %ebx,%eax
f010106c:	e8 98 fa ff ff       	call   f0100b09 <page2kva>
f0101071:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101074:	76 1e                	jbe    f0101094 <check_page_free_list+0x1fc>
f0101076:	68 8c 4a 10 f0       	push   $0xf0104a8c
f010107b:	68 7a 50 10 f0       	push   $0xf010507a
f0101080:	68 70 02 00 00       	push   $0x270
f0101085:	68 5b 50 10 f0       	push   $0xf010505b
f010108a:	e8 1a f0 ff ff       	call   f01000a9 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f010108f:	83 c7 01             	add    $0x1,%edi
f0101092:	eb 04                	jmp    f0101098 <check_page_free_list+0x200>
		else
			++nfree_extmem;
f0101094:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101098:	8b 1b                	mov    (%ebx),%ebx
f010109a:	85 db                	test   %ebx,%ebx
f010109c:	0f 85 e0 fe ff ff    	jne    f0100f82 <check_page_free_list+0xea>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01010a2:	85 ff                	test   %edi,%edi
f01010a4:	7f 19                	jg     f01010bf <check_page_free_list+0x227>
f01010a6:	68 23 51 10 f0       	push   $0xf0105123
f01010ab:	68 7a 50 10 f0       	push   $0xf010507a
f01010b0:	68 78 02 00 00       	push   $0x278
f01010b5:	68 5b 50 10 f0       	push   $0xf010505b
f01010ba:	e8 ea ef ff ff       	call   f01000a9 <_panic>
	assert(nfree_extmem > 0);
f01010bf:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01010c3:	7f 43                	jg     f0101108 <check_page_free_list+0x270>
f01010c5:	68 35 51 10 f0       	push   $0xf0105135
f01010ca:	68 7a 50 10 f0       	push   $0xf010507a
f01010cf:	68 79 02 00 00       	push   $0x279
f01010d4:	68 5b 50 10 f0       	push   $0xf010505b
f01010d9:	e8 cb ef ff ff       	call   f01000a9 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01010de:	8b 1d dc 4d 19 f0    	mov    0xf0194ddc,%ebx
f01010e4:	85 db                	test   %ebx,%ebx
f01010e6:	0f 85 d9 fd ff ff    	jne    f0100ec5 <check_page_free_list+0x2d>
f01010ec:	e9 bd fd ff ff       	jmp    f0100eae <check_page_free_list+0x16>
f01010f1:	83 3d dc 4d 19 f0 00 	cmpl   $0x0,0xf0194ddc
f01010f8:	0f 84 b0 fd ff ff    	je     f0100eae <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01010fe:	be 00 04 00 00       	mov    $0x400,%esi
f0101103:	e9 09 fe ff ff       	jmp    f0100f11 <check_page_free_list+0x79>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0101108:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010110b:	5b                   	pop    %ebx
f010110c:	5e                   	pop    %esi
f010110d:	5f                   	pop    %edi
f010110e:	5d                   	pop    %ebp
f010110f:	c3                   	ret    

f0101110 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101110:	c1 e8 0c             	shr    $0xc,%eax
f0101113:	3b 05 a4 6a 19 f0    	cmp    0xf0196aa4,%eax
f0101119:	72 17                	jb     f0101132 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f010111b:	55                   	push   %ebp
f010111c:	89 e5                	mov    %esp,%ebp
f010111e:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0101121:	68 d4 4a 10 f0       	push   $0xf0104ad4
f0101126:	6a 4f                	push   $0x4f
f0101128:	68 4d 50 10 f0       	push   $0xf010504d
f010112d:	e8 77 ef ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f0101132:	8b 15 ac 6a 19 f0    	mov    0xf0196aac,%edx
f0101138:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010113b:	c3                   	ret    

f010113c <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010113c:	55                   	push   %ebp
f010113d:	89 e5                	mov    %esp,%ebp
f010113f:	56                   	push   %esi
f0101140:	53                   	push   %ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
f0101141:	b8 00 00 00 00       	mov    $0x0,%eax
f0101146:	e8 6e fa ff ff       	call   f0100bb9 <boot_alloc>
f010114b:	89 c1                	mov    %eax,%ecx
f010114d:	ba 19 01 00 00       	mov    $0x119,%edx
f0101152:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0101157:	e8 3b fa ff ff       	call   f0100b97 <_paddr>
f010115c:	c1 e8 0c             	shr    $0xc,%eax
f010115f:	8b 35 dc 4d 19 f0    	mov    0xf0194ddc,%esi
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f0101165:	b9 00 00 00 00       	mov    $0x0,%ecx
f010116a:	ba 01 00 00 00       	mov    $0x1,%edx
f010116f:	eb 33                	jmp    f01011a4 <page_init+0x68>
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
f0101171:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101177:	76 04                	jbe    f010117d <page_init+0x41>
f0101179:	39 c2                	cmp    %eax,%edx
f010117b:	72 24                	jb     f01011a1 <page_init+0x65>
		pages[i].pp_ref = 0;
f010117d:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0101184:	89 cb                	mov    %ecx,%ebx
f0101186:	03 1d ac 6a 19 f0    	add    0xf0196aac,%ebx
f010118c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0101192:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f0101194:	89 ce                	mov    %ecx,%esi
f0101196:	03 35 ac 6a 19 f0    	add    0xf0196aac,%esi
f010119c:	b9 01 00 00 00       	mov    $0x1,%ecx
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01011a1:	83 c2 01             	add    $0x1,%edx
f01011a4:	3b 15 a4 6a 19 f0    	cmp    0xf0196aa4,%edx
f01011aa:	72 c5                	jb     f0101171 <page_init+0x35>
f01011ac:	84 c9                	test   %cl,%cl
f01011ae:	74 06                	je     f01011b6 <page_init+0x7a>
f01011b0:	89 35 dc 4d 19 f0    	mov    %esi,0xf0194ddc
		if (i>=lim_inf_IO && i<lim_sup_kernmem) continue;//asi es como se no-mapea		
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01011b6:	5b                   	pop    %ebx
f01011b7:	5e                   	pop    %esi
f01011b8:	5d                   	pop    %ebp
f01011b9:	c3                   	ret    

f01011ba <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{	if (page_free_list == NULL) return NULL;
f01011ba:	55                   	push   %ebp
f01011bb:	89 e5                	mov    %esp,%ebp
f01011bd:	53                   	push   %ebx
f01011be:	83 ec 04             	sub    $0x4,%esp
f01011c1:	8b 1d dc 4d 19 f0    	mov    0xf0194ddc,%ebx
f01011c7:	85 db                	test   %ebx,%ebx
f01011c9:	74 2d                	je     f01011f8 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f01011cb:	8b 03                	mov    (%ebx),%eax
f01011cd:	a3 dc 4d 19 f0       	mov    %eax,0xf0194ddc
	pag->pp_link = NULL;
f01011d2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) memset(page2kva(pag),0,PGSIZE);
f01011d8:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01011dc:	74 1a                	je     f01011f8 <page_alloc+0x3e>
f01011de:	89 d8                	mov    %ebx,%eax
f01011e0:	e8 24 f9 ff ff       	call   f0100b09 <page2kva>
f01011e5:	83 ec 04             	sub    $0x4,%esp
f01011e8:	68 00 10 00 00       	push   $0x1000
f01011ed:	6a 00                	push   $0x0
f01011ef:	50                   	push   %eax
f01011f0:	e8 8e 2c 00 00       	call   f0103e83 <memset>
f01011f5:	83 c4 10             	add    $0x10,%esp
	return pag;
}
f01011f8:	89 d8                	mov    %ebx,%eax
f01011fa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011fd:	c9                   	leave  
f01011fe:	c3                   	ret    

f01011ff <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01011ff:	55                   	push   %ebp
f0101200:	89 e5                	mov    %esp,%ebp
f0101202:	83 ec 08             	sub    $0x8,%esp
f0101205:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref) panic("page still in use!\n");
f0101208:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010120d:	74 17                	je     f0101226 <page_free+0x27>
f010120f:	83 ec 04             	sub    $0x4,%esp
f0101212:	68 46 51 10 f0       	push   $0xf0105146
f0101217:	68 42 01 00 00       	push   $0x142
f010121c:	68 5b 50 10 f0       	push   $0xf010505b
f0101221:	e8 83 ee ff ff       	call   f01000a9 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f0101226:	83 38 00             	cmpl   $0x0,(%eax)
f0101229:	74 17                	je     f0101242 <page_free+0x43>
f010122b:	83 ec 04             	sub    $0x4,%esp
f010122e:	68 f4 4a 10 f0       	push   $0xf0104af4
f0101233:	68 43 01 00 00       	push   $0x143
f0101238:	68 5b 50 10 f0       	push   $0xf010505b
f010123d:	e8 67 ee ff ff       	call   f01000a9 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f0101242:	8b 15 dc 4d 19 f0    	mov    0xf0194ddc,%edx
f0101248:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f010124a:	a3 dc 4d 19 f0       	mov    %eax,0xf0194ddc
}
f010124f:	c9                   	leave  
f0101250:	c3                   	ret    

f0101251 <check_page_alloc>:
// Check the physical page allocator (page_alloc(), page_free(),
// and page_init()).
//
static void
check_page_alloc(void)
{
f0101251:	55                   	push   %ebp
f0101252:	89 e5                	mov    %esp,%ebp
f0101254:	57                   	push   %edi
f0101255:	56                   	push   %esi
f0101256:	53                   	push   %ebx
f0101257:	83 ec 1c             	sub    $0x1c,%esp
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010125a:	83 3d ac 6a 19 f0 00 	cmpl   $0x0,0xf0196aac
f0101261:	75 17                	jne    f010127a <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f0101263:	83 ec 04             	sub    $0x4,%esp
f0101266:	68 5a 51 10 f0       	push   $0xf010515a
f010126b:	68 8a 02 00 00       	push   $0x28a
f0101270:	68 5b 50 10 f0       	push   $0xf010505b
f0101275:	e8 2f ee ff ff       	call   f01000a9 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010127a:	a1 dc 4d 19 f0       	mov    0xf0194ddc,%eax
f010127f:	be 00 00 00 00       	mov    $0x0,%esi
f0101284:	eb 05                	jmp    f010128b <check_page_alloc+0x3a>
		++nfree;
f0101286:	83 c6 01             	add    $0x1,%esi

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101289:	8b 00                	mov    (%eax),%eax
f010128b:	85 c0                	test   %eax,%eax
f010128d:	75 f7                	jne    f0101286 <check_page_alloc+0x35>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010128f:	83 ec 0c             	sub    $0xc,%esp
f0101292:	6a 00                	push   $0x0
f0101294:	e8 21 ff ff ff       	call   f01011ba <page_alloc>
f0101299:	89 c7                	mov    %eax,%edi
f010129b:	83 c4 10             	add    $0x10,%esp
f010129e:	85 c0                	test   %eax,%eax
f01012a0:	75 19                	jne    f01012bb <check_page_alloc+0x6a>
f01012a2:	68 75 51 10 f0       	push   $0xf0105175
f01012a7:	68 7a 50 10 f0       	push   $0xf010507a
f01012ac:	68 92 02 00 00       	push   $0x292
f01012b1:	68 5b 50 10 f0       	push   $0xf010505b
f01012b6:	e8 ee ed ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01012bb:	83 ec 0c             	sub    $0xc,%esp
f01012be:	6a 00                	push   $0x0
f01012c0:	e8 f5 fe ff ff       	call   f01011ba <page_alloc>
f01012c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012c8:	83 c4 10             	add    $0x10,%esp
f01012cb:	85 c0                	test   %eax,%eax
f01012cd:	75 19                	jne    f01012e8 <check_page_alloc+0x97>
f01012cf:	68 8b 51 10 f0       	push   $0xf010518b
f01012d4:	68 7a 50 10 f0       	push   $0xf010507a
f01012d9:	68 93 02 00 00       	push   $0x293
f01012de:	68 5b 50 10 f0       	push   $0xf010505b
f01012e3:	e8 c1 ed ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01012e8:	83 ec 0c             	sub    $0xc,%esp
f01012eb:	6a 00                	push   $0x0
f01012ed:	e8 c8 fe ff ff       	call   f01011ba <page_alloc>
f01012f2:	89 c3                	mov    %eax,%ebx
f01012f4:	83 c4 10             	add    $0x10,%esp
f01012f7:	85 c0                	test   %eax,%eax
f01012f9:	75 19                	jne    f0101314 <check_page_alloc+0xc3>
f01012fb:	68 a1 51 10 f0       	push   $0xf01051a1
f0101300:	68 7a 50 10 f0       	push   $0xf010507a
f0101305:	68 94 02 00 00       	push   $0x294
f010130a:	68 5b 50 10 f0       	push   $0xf010505b
f010130f:	e8 95 ed ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101314:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101317:	75 19                	jne    f0101332 <check_page_alloc+0xe1>
f0101319:	68 b7 51 10 f0       	push   $0xf01051b7
f010131e:	68 7a 50 10 f0       	push   $0xf010507a
f0101323:	68 97 02 00 00       	push   $0x297
f0101328:	68 5b 50 10 f0       	push   $0xf010505b
f010132d:	e8 77 ed ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101332:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101335:	74 04                	je     f010133b <check_page_alloc+0xea>
f0101337:	39 c7                	cmp    %eax,%edi
f0101339:	75 19                	jne    f0101354 <check_page_alloc+0x103>
f010133b:	68 20 4b 10 f0       	push   $0xf0104b20
f0101340:	68 7a 50 10 f0       	push   $0xf010507a
f0101345:	68 98 02 00 00       	push   $0x298
f010134a:	68 5b 50 10 f0       	push   $0xf010505b
f010134f:	e8 55 ed ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101354:	89 f8                	mov    %edi,%eax
f0101356:	e8 e2 f6 ff ff       	call   f0100a3d <page2pa>
f010135b:	8b 0d a4 6a 19 f0    	mov    0xf0196aa4,%ecx
f0101361:	c1 e1 0c             	shl    $0xc,%ecx
f0101364:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101367:	39 c8                	cmp    %ecx,%eax
f0101369:	72 19                	jb     f0101384 <check_page_alloc+0x133>
f010136b:	68 c9 51 10 f0       	push   $0xf01051c9
f0101370:	68 7a 50 10 f0       	push   $0xf010507a
f0101375:	68 99 02 00 00       	push   $0x299
f010137a:	68 5b 50 10 f0       	push   $0xf010505b
f010137f:	e8 25 ed ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101384:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101387:	e8 b1 f6 ff ff       	call   f0100a3d <page2pa>
f010138c:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010138f:	77 19                	ja     f01013aa <check_page_alloc+0x159>
f0101391:	68 e6 51 10 f0       	push   $0xf01051e6
f0101396:	68 7a 50 10 f0       	push   $0xf010507a
f010139b:	68 9a 02 00 00       	push   $0x29a
f01013a0:	68 5b 50 10 f0       	push   $0xf010505b
f01013a5:	e8 ff ec ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013aa:	89 d8                	mov    %ebx,%eax
f01013ac:	e8 8c f6 ff ff       	call   f0100a3d <page2pa>
f01013b1:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01013b4:	77 19                	ja     f01013cf <check_page_alloc+0x17e>
f01013b6:	68 03 52 10 f0       	push   $0xf0105203
f01013bb:	68 7a 50 10 f0       	push   $0xf010507a
f01013c0:	68 9b 02 00 00       	push   $0x29b
f01013c5:	68 5b 50 10 f0       	push   $0xf010505b
f01013ca:	e8 da ec ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013cf:	a1 dc 4d 19 f0       	mov    0xf0194ddc,%eax
f01013d4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01013d7:	c7 05 dc 4d 19 f0 00 	movl   $0x0,0xf0194ddc
f01013de:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013e1:	83 ec 0c             	sub    $0xc,%esp
f01013e4:	6a 00                	push   $0x0
f01013e6:	e8 cf fd ff ff       	call   f01011ba <page_alloc>
f01013eb:	83 c4 10             	add    $0x10,%esp
f01013ee:	85 c0                	test   %eax,%eax
f01013f0:	74 19                	je     f010140b <check_page_alloc+0x1ba>
f01013f2:	68 20 52 10 f0       	push   $0xf0105220
f01013f7:	68 7a 50 10 f0       	push   $0xf010507a
f01013fc:	68 a2 02 00 00       	push   $0x2a2
f0101401:	68 5b 50 10 f0       	push   $0xf010505b
f0101406:	e8 9e ec ff ff       	call   f01000a9 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010140b:	83 ec 0c             	sub    $0xc,%esp
f010140e:	57                   	push   %edi
f010140f:	e8 eb fd ff ff       	call   f01011ff <page_free>
	page_free(pp1);
f0101414:	83 c4 04             	add    $0x4,%esp
f0101417:	ff 75 e4             	pushl  -0x1c(%ebp)
f010141a:	e8 e0 fd ff ff       	call   f01011ff <page_free>
	page_free(pp2);
f010141f:	89 1c 24             	mov    %ebx,(%esp)
f0101422:	e8 d8 fd ff ff       	call   f01011ff <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101427:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010142e:	e8 87 fd ff ff       	call   f01011ba <page_alloc>
f0101433:	89 c3                	mov    %eax,%ebx
f0101435:	83 c4 10             	add    $0x10,%esp
f0101438:	85 c0                	test   %eax,%eax
f010143a:	75 19                	jne    f0101455 <check_page_alloc+0x204>
f010143c:	68 75 51 10 f0       	push   $0xf0105175
f0101441:	68 7a 50 10 f0       	push   $0xf010507a
f0101446:	68 a9 02 00 00       	push   $0x2a9
f010144b:	68 5b 50 10 f0       	push   $0xf010505b
f0101450:	e8 54 ec ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101455:	83 ec 0c             	sub    $0xc,%esp
f0101458:	6a 00                	push   $0x0
f010145a:	e8 5b fd ff ff       	call   f01011ba <page_alloc>
f010145f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101462:	83 c4 10             	add    $0x10,%esp
f0101465:	85 c0                	test   %eax,%eax
f0101467:	75 19                	jne    f0101482 <check_page_alloc+0x231>
f0101469:	68 8b 51 10 f0       	push   $0xf010518b
f010146e:	68 7a 50 10 f0       	push   $0xf010507a
f0101473:	68 aa 02 00 00       	push   $0x2aa
f0101478:	68 5b 50 10 f0       	push   $0xf010505b
f010147d:	e8 27 ec ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101482:	83 ec 0c             	sub    $0xc,%esp
f0101485:	6a 00                	push   $0x0
f0101487:	e8 2e fd ff ff       	call   f01011ba <page_alloc>
f010148c:	89 c7                	mov    %eax,%edi
f010148e:	83 c4 10             	add    $0x10,%esp
f0101491:	85 c0                	test   %eax,%eax
f0101493:	75 19                	jne    f01014ae <check_page_alloc+0x25d>
f0101495:	68 a1 51 10 f0       	push   $0xf01051a1
f010149a:	68 7a 50 10 f0       	push   $0xf010507a
f010149f:	68 ab 02 00 00       	push   $0x2ab
f01014a4:	68 5b 50 10 f0       	push   $0xf010505b
f01014a9:	e8 fb eb ff ff       	call   f01000a9 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014ae:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01014b1:	75 19                	jne    f01014cc <check_page_alloc+0x27b>
f01014b3:	68 b7 51 10 f0       	push   $0xf01051b7
f01014b8:	68 7a 50 10 f0       	push   $0xf010507a
f01014bd:	68 ad 02 00 00       	push   $0x2ad
f01014c2:	68 5b 50 10 f0       	push   $0xf010505b
f01014c7:	e8 dd eb ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014cc:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01014cf:	74 04                	je     f01014d5 <check_page_alloc+0x284>
f01014d1:	39 c3                	cmp    %eax,%ebx
f01014d3:	75 19                	jne    f01014ee <check_page_alloc+0x29d>
f01014d5:	68 20 4b 10 f0       	push   $0xf0104b20
f01014da:	68 7a 50 10 f0       	push   $0xf010507a
f01014df:	68 ae 02 00 00       	push   $0x2ae
f01014e4:	68 5b 50 10 f0       	push   $0xf010505b
f01014e9:	e8 bb eb ff ff       	call   f01000a9 <_panic>
	assert(!page_alloc(0));
f01014ee:	83 ec 0c             	sub    $0xc,%esp
f01014f1:	6a 00                	push   $0x0
f01014f3:	e8 c2 fc ff ff       	call   f01011ba <page_alloc>
f01014f8:	83 c4 10             	add    $0x10,%esp
f01014fb:	85 c0                	test   %eax,%eax
f01014fd:	74 19                	je     f0101518 <check_page_alloc+0x2c7>
f01014ff:	68 20 52 10 f0       	push   $0xf0105220
f0101504:	68 7a 50 10 f0       	push   $0xf010507a
f0101509:	68 af 02 00 00       	push   $0x2af
f010150e:	68 5b 50 10 f0       	push   $0xf010505b
f0101513:	e8 91 eb ff ff       	call   f01000a9 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101518:	89 d8                	mov    %ebx,%eax
f010151a:	e8 ea f5 ff ff       	call   f0100b09 <page2kva>
f010151f:	83 ec 04             	sub    $0x4,%esp
f0101522:	68 00 10 00 00       	push   $0x1000
f0101527:	6a 01                	push   $0x1
f0101529:	50                   	push   %eax
f010152a:	e8 54 29 00 00       	call   f0103e83 <memset>
	page_free(pp0);
f010152f:	89 1c 24             	mov    %ebx,(%esp)
f0101532:	e8 c8 fc ff ff       	call   f01011ff <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101537:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010153e:	e8 77 fc ff ff       	call   f01011ba <page_alloc>
f0101543:	83 c4 10             	add    $0x10,%esp
f0101546:	85 c0                	test   %eax,%eax
f0101548:	75 19                	jne    f0101563 <check_page_alloc+0x312>
f010154a:	68 2f 52 10 f0       	push   $0xf010522f
f010154f:	68 7a 50 10 f0       	push   $0xf010507a
f0101554:	68 b4 02 00 00       	push   $0x2b4
f0101559:	68 5b 50 10 f0       	push   $0xf010505b
f010155e:	e8 46 eb ff ff       	call   f01000a9 <_panic>
	assert(pp && pp0 == pp);
f0101563:	39 c3                	cmp    %eax,%ebx
f0101565:	74 19                	je     f0101580 <check_page_alloc+0x32f>
f0101567:	68 4d 52 10 f0       	push   $0xf010524d
f010156c:	68 7a 50 10 f0       	push   $0xf010507a
f0101571:	68 b5 02 00 00       	push   $0x2b5
f0101576:	68 5b 50 10 f0       	push   $0xf010505b
f010157b:	e8 29 eb ff ff       	call   f01000a9 <_panic>
	c = page2kva(pp);
f0101580:	89 d8                	mov    %ebx,%eax
f0101582:	e8 82 f5 ff ff       	call   f0100b09 <page2kva>
f0101587:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010158d:	80 38 00             	cmpb   $0x0,(%eax)
f0101590:	74 19                	je     f01015ab <check_page_alloc+0x35a>
f0101592:	68 5d 52 10 f0       	push   $0xf010525d
f0101597:	68 7a 50 10 f0       	push   $0xf010507a
f010159c:	68 b8 02 00 00       	push   $0x2b8
f01015a1:	68 5b 50 10 f0       	push   $0xf010505b
f01015a6:	e8 fe ea ff ff       	call   f01000a9 <_panic>
f01015ab:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01015ae:	39 d0                	cmp    %edx,%eax
f01015b0:	75 db                	jne    f010158d <check_page_alloc+0x33c>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01015b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01015b5:	a3 dc 4d 19 f0       	mov    %eax,0xf0194ddc

	// free the pages we took
	page_free(pp0);
f01015ba:	83 ec 0c             	sub    $0xc,%esp
f01015bd:	53                   	push   %ebx
f01015be:	e8 3c fc ff ff       	call   f01011ff <page_free>
	page_free(pp1);
f01015c3:	83 c4 04             	add    $0x4,%esp
f01015c6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01015c9:	e8 31 fc ff ff       	call   f01011ff <page_free>
	page_free(pp2);
f01015ce:	89 3c 24             	mov    %edi,(%esp)
f01015d1:	e8 29 fc ff ff       	call   f01011ff <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015d6:	a1 dc 4d 19 f0       	mov    0xf0194ddc,%eax
f01015db:	83 c4 10             	add    $0x10,%esp
f01015de:	eb 05                	jmp    f01015e5 <check_page_alloc+0x394>
		--nfree;
f01015e0:	83 ee 01             	sub    $0x1,%esi
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01015e3:	8b 00                	mov    (%eax),%eax
f01015e5:	85 c0                	test   %eax,%eax
f01015e7:	75 f7                	jne    f01015e0 <check_page_alloc+0x38f>
		--nfree;
	assert(nfree == 0);
f01015e9:	85 f6                	test   %esi,%esi
f01015eb:	74 19                	je     f0101606 <check_page_alloc+0x3b5>
f01015ed:	68 67 52 10 f0       	push   $0xf0105267
f01015f2:	68 7a 50 10 f0       	push   $0xf010507a
f01015f7:	68 c5 02 00 00       	push   $0x2c5
f01015fc:	68 5b 50 10 f0       	push   $0xf010505b
f0101601:	e8 a3 ea ff ff       	call   f01000a9 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101606:	83 ec 0c             	sub    $0xc,%esp
f0101609:	68 40 4b 10 f0       	push   $0xf0104b40
f010160e:	e8 bc 19 00 00       	call   f0102fcf <cprintf>
}
f0101613:	83 c4 10             	add    $0x10,%esp
f0101616:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101619:	5b                   	pop    %ebx
f010161a:	5e                   	pop    %esi
f010161b:	5f                   	pop    %edi
f010161c:	5d                   	pop    %ebp
f010161d:	c3                   	ret    

f010161e <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010161e:	55                   	push   %ebp
f010161f:	89 e5                	mov    %esp,%ebp
f0101621:	83 ec 08             	sub    $0x8,%esp
f0101624:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101627:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010162b:	83 e8 01             	sub    $0x1,%eax
f010162e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101632:	66 85 c0             	test   %ax,%ax
f0101635:	75 0c                	jne    f0101643 <page_decref+0x25>
		page_free(pp);
f0101637:	83 ec 0c             	sub    $0xc,%esp
f010163a:	52                   	push   %edx
f010163b:	e8 bf fb ff ff       	call   f01011ff <page_free>
f0101640:	83 c4 10             	add    $0x10,%esp
}
f0101643:	c9                   	leave  
f0101644:	c3                   	ret    

f0101645 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101645:	55                   	push   %ebp
f0101646:	89 e5                	mov    %esp,%ebp
f0101648:	57                   	push   %edi
f0101649:	56                   	push   %esi
f010164a:	53                   	push   %ebx
f010164b:	83 ec 0c             	sub    $0xc,%esp
f010164e:	8b 75 0c             	mov    0xc(%ebp),%esi
	pde_t pde =  pgdir[PDX(va)]; //ojo que esto es P.Addr. !!
f0101651:	89 f3                	mov    %esi,%ebx
f0101653:	c1 eb 16             	shr    $0x16,%ebx
f0101656:	c1 e3 02             	shl    $0x2,%ebx
f0101659:	03 5d 08             	add    0x8(%ebp),%ebx
f010165c:	8b 3b                	mov    (%ebx),%edi
	pte_t* pte = (pte_t*) KADDR(PTE_ADDR(pde));
f010165e:	89 f9                	mov    %edi,%ecx
f0101660:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101666:	ba 6e 01 00 00       	mov    $0x16e,%edx
f010166b:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0101670:	e8 68 f4 ff ff       	call   f0100add <_kaddr>

	if (pde & PTE_P) return pte+PTX(va);
f0101675:	f7 c7 01 00 00 00    	test   $0x1,%edi
f010167b:	74 0d                	je     f010168a <pgdir_walk+0x45>
f010167d:	c1 ee 0a             	shr    $0xa,%esi
f0101680:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101686:	01 f0                	add    %esi,%eax
f0101688:	eb 52                	jmp    f01016dc <pgdir_walk+0x97>

	if (!create) return NULL;
f010168a:	b8 00 00 00 00       	mov    $0x0,%eax
f010168f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101693:	74 47                	je     f01016dc <pgdir_walk+0x97>
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
f0101695:	83 ec 0c             	sub    $0xc,%esp
f0101698:	6a 01                	push   $0x1
f010169a:	e8 1b fb ff ff       	call   f01011ba <page_alloc>
f010169f:	89 c7                	mov    %eax,%edi
	if (page==NULL) return NULL;
f01016a1:	83 c4 10             	add    $0x10,%esp
f01016a4:	85 c0                	test   %eax,%eax
f01016a6:	74 2f                	je     f01016d7 <pgdir_walk+0x92>
	physaddr_t pt_start = page2pa(page);
f01016a8:	e8 90 f3 ff ff       	call   f0100a3d <page2pa>
	page->pp_ref ++;
f01016ad:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
f01016b2:	89 c2                	mov    %eax,%edx
f01016b4:	83 ca 07             	or     $0x7,%edx
f01016b7:	89 13                	mov    %edx,(%ebx)
	return (pte_t*)KADDR(pt_start)+PTX(va);
f01016b9:	89 c1                	mov    %eax,%ecx
f01016bb:	ba 78 01 00 00       	mov    $0x178,%edx
f01016c0:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f01016c5:	e8 13 f4 ff ff       	call   f0100add <_kaddr>
f01016ca:	c1 ee 0a             	shr    $0xa,%esi
f01016cd:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01016d3:	01 f0                	add    %esi,%eax
f01016d5:	eb 05                	jmp    f01016dc <pgdir_walk+0x97>

	if (pde & PTE_P) return pte+PTX(va);

	if (!create) return NULL;
	struct PageInfo *page = page_alloc(ALLOC_ZERO);
	if (page==NULL) return NULL;
f01016d7:	b8 00 00 00 00       	mov    $0x0,%eax
	physaddr_t pt_start = page2pa(page);
	page->pp_ref ++;
	*(pgdir+PDX(va)) = pt_start | PTE_P | PTE_U | PTE_W;
	return (pte_t*)KADDR(pt_start)+PTX(va);
}
f01016dc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01016df:	5b                   	pop    %ebx
f01016e0:	5e                   	pop    %esi
f01016e1:	5f                   	pop    %edi
f01016e2:	5d                   	pop    %ebp
f01016e3:	c3                   	ret    

f01016e4 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk
//#define TP1_PSE 1
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01016e4:	55                   	push   %ebp
f01016e5:	89 e5                	mov    %esp,%ebp
f01016e7:	57                   	push   %edi
f01016e8:	56                   	push   %esi
f01016e9:	53                   	push   %ebx
f01016ea:	83 ec 1c             	sub    $0x1c,%esp
f01016ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01016f0:	8b 45 08             	mov    0x8(%ebp),%eax
	assert(va % PGSIZE == 0);
f01016f3:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01016f9:	74 19                	je     f0101714 <boot_map_region+0x30>
f01016fb:	68 72 52 10 f0       	push   $0xf0105272
f0101700:	68 7a 50 10 f0       	push   $0xf010507a
f0101705:	68 8a 01 00 00       	push   $0x18a
f010170a:	68 5b 50 10 f0       	push   $0xf010505b
f010170f:	e8 95 e9 ff ff       	call   f01000a9 <_panic>
f0101714:	89 cf                	mov    %ecx,%edi
	assert(pa % PGSIZE == 0);
f0101716:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010171b:	74 19                	je     f0101736 <boot_map_region+0x52>
f010171d:	68 83 52 10 f0       	push   $0xf0105283
f0101722:	68 7a 50 10 f0       	push   $0xf010507a
f0101727:	68 8b 01 00 00       	push   $0x18b
f010172c:	68 5b 50 10 f0       	push   $0xf010505b
f0101731:	e8 73 e9 ff ff       	call   f01000a9 <_panic>
	assert(size % PGSIZE == 0);	
f0101736:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010173c:	74 3d                	je     f010177b <boot_map_region+0x97>
f010173e:	68 94 52 10 f0       	push   $0xf0105294
f0101743:	68 7a 50 10 f0       	push   $0xf010507a
f0101748:	68 8c 01 00 00       	push   $0x18c
f010174d:	68 5b 50 10 f0       	push   $0xf010505b
f0101752:	e8 52 e9 ff ff       	call   f01000a9 <_panic>
	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
f0101757:	83 ec 04             	sub    $0x4,%esp
f010175a:	6a 01                	push   $0x1
f010175c:	53                   	push   %ebx
f010175d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101760:	e8 e0 fe ff ff       	call   f0101645 <pgdir_walk>
			*pte_addr = pa | perm | PTE_P;
f0101765:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101768:	89 30                	mov    %esi,(%eax)
			size-=PGSIZE;		
f010176a:	81 ef 00 10 00 00    	sub    $0x1000,%edi
			//incremento
			va+=PGSIZE;
f0101770:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101776:	83 c4 10             	add    $0x10,%esp
f0101779:	eb 10                	jmp    f010178b <boot_map_region+0xa7>
f010177b:	89 d3                	mov    %edx,%ebx
f010177d:	29 d0                	sub    %edx,%eax
f010177f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
			pte_t* pte_addr = pgdir_walk(pgdir,(void*)va,true);
			*pte_addr = pa | perm | PTE_P;
f0101782:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101785:	83 c8 01             	or     $0x1,%eax
f0101788:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010178b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010178e:	8d 34 18             	lea    (%eax,%ebx,1),%esi

	//uint32_t cant_iteraciones = size/PGSIZE;
	//for (int i=0;i<cant_iteraciones;i++){//al ser iteraciones fijas no hay problema de overflow
	//physaddr_t pa_inicial = pa;	
	#ifndef TP1_PSE
		while(size){			
f0101791:	85 ff                	test   %edi,%edi
f0101793:	75 c2                	jne    f0101757 <boot_map_region+0x73>
				va+=PGSIZE;
				pa+=PGSIZE;
			}
		}
	#endif
}
f0101795:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101798:	5b                   	pop    %ebx
f0101799:	5e                   	pop    %esi
f010179a:	5f                   	pop    %edi
f010179b:	5d                   	pop    %ebp
f010179c:	c3                   	ret    

f010179d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010179d:	55                   	push   %ebp
f010179e:	89 e5                	mov    %esp,%ebp
f01017a0:	53                   	push   %ebx
f01017a1:	83 ec 08             	sub    $0x8,%esp
f01017a4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
f01017a7:	6a 00                	push   $0x0
f01017a9:	ff 75 0c             	pushl  0xc(%ebp)
f01017ac:	ff 75 08             	pushl  0x8(%ebp)
f01017af:	e8 91 fe ff ff       	call   f0101645 <pgdir_walk>
	if (pte_store) *pte_store = pte_addr;
f01017b4:	83 c4 10             	add    $0x10,%esp
f01017b7:	85 db                	test   %ebx,%ebx
f01017b9:	74 02                	je     f01017bd <page_lookup+0x20>
f01017bb:	89 03                	mov    %eax,(%ebx)
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f01017bd:	85 c0                	test   %eax,%eax
f01017bf:	74 1a                	je     f01017db <page_lookup+0x3e>
	if (!(*pte_addr & PTE_P)) return NULL;
f01017c1:	8b 10                	mov    (%eax),%edx
f01017c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01017c8:	f6 c2 01             	test   $0x1,%dl
f01017cb:	74 13                	je     f01017e0 <page_lookup+0x43>
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
f01017cd:	89 d0                	mov    %edx,%eax
f01017cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01017d4:	e8 37 f9 ff ff       	call   f0101110 <pa2page>
f01017d9:	eb 05                	jmp    f01017e0 <page_lookup+0x43>
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,false);
	if (pte_store) *pte_store = pte_addr;
	if (!pte_addr) return NULL;		//no recuerdo si era lazy checking o no, por las dudas dejo asi
f01017db:	b8 00 00 00 00       	mov    $0x0,%eax
	if (!(*pte_addr & PTE_P)) return NULL;
	physaddr_t pageaddr = PTE_ADDR(*pte_addr);
	return pa2page(pageaddr);
}
f01017e0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01017e3:	c9                   	leave  
f01017e4:	c3                   	ret    

f01017e5 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01017e5:	55                   	push   %ebp
f01017e6:	89 e5                	mov    %esp,%ebp
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
f01017e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017eb:	e8 2d f2 ff ff       	call   f0100a1d <invlpg>
}
f01017f0:	5d                   	pop    %ebp
f01017f1:	c3                   	ret    

f01017f2 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01017f2:	55                   	push   %ebp
f01017f3:	89 e5                	mov    %esp,%ebp
f01017f5:	56                   	push   %esi
f01017f6:	53                   	push   %ebx
f01017f7:	83 ec 14             	sub    $0x14,%esp
f01017fa:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01017fd:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t* pte_addr;
	struct PageInfo* page_ptr = page_lookup(pgdir,va,&pte_addr);
f0101800:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101803:	50                   	push   %eax
f0101804:	56                   	push   %esi
f0101805:	53                   	push   %ebx
f0101806:	e8 92 ff ff ff       	call   f010179d <page_lookup>
	if (!page_ptr) return;
f010180b:	83 c4 10             	add    $0x10,%esp
f010180e:	85 c0                	test   %eax,%eax
f0101810:	74 1f                	je     f0101831 <page_remove+0x3f>
	page_decref(page_ptr);
f0101812:	83 ec 0c             	sub    $0xc,%esp
f0101815:	50                   	push   %eax
f0101816:	e8 03 fe ff ff       	call   f010161e <page_decref>
	*pte_addr = 0;
f010181b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010181e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir,va);
f0101824:	83 c4 08             	add    $0x8,%esp
f0101827:	56                   	push   %esi
f0101828:	53                   	push   %ebx
f0101829:	e8 b7 ff ff ff       	call   f01017e5 <tlb_invalidate>
f010182e:	83 c4 10             	add    $0x10,%esp
}
f0101831:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0101834:	5b                   	pop    %ebx
f0101835:	5e                   	pop    %esi
f0101836:	5d                   	pop    %ebp
f0101837:	c3                   	ret    

f0101838 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101838:	55                   	push   %ebp
f0101839:	89 e5                	mov    %esp,%ebp
f010183b:	57                   	push   %edi
f010183c:	56                   	push   %esi
f010183d:	53                   	push   %ebx
f010183e:	83 ec 10             	sub    $0x10,%esp
f0101841:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101844:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
f0101847:	6a 01                	push   $0x1
f0101849:	57                   	push   %edi
f010184a:	ff 75 08             	pushl  0x8(%ebp)
f010184d:	e8 f3 fd ff ff       	call   f0101645 <pgdir_walk>
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f0101852:	83 c4 10             	add    $0x10,%esp
f0101855:	85 c0                	test   %eax,%eax
f0101857:	74 33                	je     f010188c <page_insert+0x54>
f0101859:	89 c6                	mov    %eax,%esi
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
f010185b:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
f0101860:	f6 00 01             	testb  $0x1,(%eax)
f0101863:	74 0f                	je     f0101874 <page_insert+0x3c>
f0101865:	83 ec 08             	sub    $0x8,%esp
f0101868:	57                   	push   %edi
f0101869:	ff 75 08             	pushl  0x8(%ebp)
f010186c:	e8 81 ff ff ff       	call   f01017f2 <page_remove>
f0101871:	83 c4 10             	add    $0x10,%esp
	*pte_addr = page2pa(pp) | perm | PTE_P;
f0101874:	89 d8                	mov    %ebx,%eax
f0101876:	e8 c2 f1 ff ff       	call   f0100a3d <page2pa>
f010187b:	8b 55 14             	mov    0x14(%ebp),%edx
f010187e:	83 ca 01             	or     $0x1,%edx
f0101881:	09 d0                	or     %edx,%eax
f0101883:	89 06                	mov    %eax,(%esi)
	return 0;
f0101885:	b8 00 00 00 00       	mov    $0x0,%eax
f010188a:	eb 05                	jmp    f0101891 <page_insert+0x59>
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t* pte_addr = pgdir_walk(pgdir,va,true);//entra a la PT, si no habia la crea
	if (!pte_addr) return -E_NO_MEM;	//solo NULL si no habia y no la pudo crear
f010188c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	//a partir de aca hay pte_addr valida
	pp->pp_ref++;
	if (*pte_addr & PTE_P) page_remove(pgdir,va);
	*pte_addr = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101891:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101894:	5b                   	pop    %ebx
f0101895:	5e                   	pop    %esi
f0101896:	5f                   	pop    %edi
f0101897:	5d                   	pop    %ebp
f0101898:	c3                   	ret    

f0101899 <check_page>:


// check page_insert, page_remove, &c
static void
check_page(void)
{
f0101899:	55                   	push   %ebp
f010189a:	89 e5                	mov    %esp,%ebp
f010189c:	57                   	push   %edi
f010189d:	56                   	push   %esi
f010189e:	53                   	push   %ebx
f010189f:	83 ec 38             	sub    $0x38,%esp
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01018a2:	6a 00                	push   $0x0
f01018a4:	e8 11 f9 ff ff       	call   f01011ba <page_alloc>
f01018a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01018ac:	83 c4 10             	add    $0x10,%esp
f01018af:	85 c0                	test   %eax,%eax
f01018b1:	75 19                	jne    f01018cc <check_page+0x33>
f01018b3:	68 75 51 10 f0       	push   $0xf0105175
f01018b8:	68 7a 50 10 f0       	push   $0xf010507a
f01018bd:	68 2f 03 00 00       	push   $0x32f
f01018c2:	68 5b 50 10 f0       	push   $0xf010505b
f01018c7:	e8 dd e7 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01018cc:	83 ec 0c             	sub    $0xc,%esp
f01018cf:	6a 00                	push   $0x0
f01018d1:	e8 e4 f8 ff ff       	call   f01011ba <page_alloc>
f01018d6:	89 c6                	mov    %eax,%esi
f01018d8:	83 c4 10             	add    $0x10,%esp
f01018db:	85 c0                	test   %eax,%eax
f01018dd:	75 19                	jne    f01018f8 <check_page+0x5f>
f01018df:	68 8b 51 10 f0       	push   $0xf010518b
f01018e4:	68 7a 50 10 f0       	push   $0xf010507a
f01018e9:	68 30 03 00 00       	push   $0x330
f01018ee:	68 5b 50 10 f0       	push   $0xf010505b
f01018f3:	e8 b1 e7 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f8:	83 ec 0c             	sub    $0xc,%esp
f01018fb:	6a 00                	push   $0x0
f01018fd:	e8 b8 f8 ff ff       	call   f01011ba <page_alloc>
f0101902:	89 c3                	mov    %eax,%ebx
f0101904:	83 c4 10             	add    $0x10,%esp
f0101907:	85 c0                	test   %eax,%eax
f0101909:	75 19                	jne    f0101924 <check_page+0x8b>
f010190b:	68 a1 51 10 f0       	push   $0xf01051a1
f0101910:	68 7a 50 10 f0       	push   $0xf010507a
f0101915:	68 31 03 00 00       	push   $0x331
f010191a:	68 5b 50 10 f0       	push   $0xf010505b
f010191f:	e8 85 e7 ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101924:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101927:	75 19                	jne    f0101942 <check_page+0xa9>
f0101929:	68 b7 51 10 f0       	push   $0xf01051b7
f010192e:	68 7a 50 10 f0       	push   $0xf010507a
f0101933:	68 34 03 00 00       	push   $0x334
f0101938:	68 5b 50 10 f0       	push   $0xf010505b
f010193d:	e8 67 e7 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101942:	39 c6                	cmp    %eax,%esi
f0101944:	74 05                	je     f010194b <check_page+0xb2>
f0101946:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101949:	75 19                	jne    f0101964 <check_page+0xcb>
f010194b:	68 20 4b 10 f0       	push   $0xf0104b20
f0101950:	68 7a 50 10 f0       	push   $0xf010507a
f0101955:	68 35 03 00 00       	push   $0x335
f010195a:	68 5b 50 10 f0       	push   $0xf010505b
f010195f:	e8 45 e7 ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101964:	a1 dc 4d 19 f0       	mov    0xf0194ddc,%eax
f0101969:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010196c:	c7 05 dc 4d 19 f0 00 	movl   $0x0,0xf0194ddc
f0101973:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101976:	83 ec 0c             	sub    $0xc,%esp
f0101979:	6a 00                	push   $0x0
f010197b:	e8 3a f8 ff ff       	call   f01011ba <page_alloc>
f0101980:	83 c4 10             	add    $0x10,%esp
f0101983:	85 c0                	test   %eax,%eax
f0101985:	74 19                	je     f01019a0 <check_page+0x107>
f0101987:	68 20 52 10 f0       	push   $0xf0105220
f010198c:	68 7a 50 10 f0       	push   $0xf010507a
f0101991:	68 3c 03 00 00       	push   $0x33c
f0101996:	68 5b 50 10 f0       	push   $0xf010505b
f010199b:	e8 09 e7 ff ff       	call   f01000a9 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019a0:	83 ec 04             	sub    $0x4,%esp
f01019a3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019a6:	50                   	push   %eax
f01019a7:	6a 00                	push   $0x0
f01019a9:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f01019af:	e8 e9 fd ff ff       	call   f010179d <page_lookup>
f01019b4:	83 c4 10             	add    $0x10,%esp
f01019b7:	85 c0                	test   %eax,%eax
f01019b9:	74 19                	je     f01019d4 <check_page+0x13b>
f01019bb:	68 60 4b 10 f0       	push   $0xf0104b60
f01019c0:	68 7a 50 10 f0       	push   $0xf010507a
f01019c5:	68 3f 03 00 00       	push   $0x33f
f01019ca:	68 5b 50 10 f0       	push   $0xf010505b
f01019cf:	e8 d5 e6 ff ff       	call   f01000a9 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019d4:	6a 02                	push   $0x2
f01019d6:	6a 00                	push   $0x0
f01019d8:	56                   	push   %esi
f01019d9:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f01019df:	e8 54 fe ff ff       	call   f0101838 <page_insert>
f01019e4:	83 c4 10             	add    $0x10,%esp
f01019e7:	85 c0                	test   %eax,%eax
f01019e9:	78 19                	js     f0101a04 <check_page+0x16b>
f01019eb:	68 98 4b 10 f0       	push   $0xf0104b98
f01019f0:	68 7a 50 10 f0       	push   $0xf010507a
f01019f5:	68 42 03 00 00       	push   $0x342
f01019fa:	68 5b 50 10 f0       	push   $0xf010505b
f01019ff:	e8 a5 e6 ff ff       	call   f01000a9 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a04:	83 ec 0c             	sub    $0xc,%esp
f0101a07:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101a0a:	e8 f0 f7 ff ff       	call   f01011ff <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a0f:	6a 02                	push   $0x2
f0101a11:	6a 00                	push   $0x0
f0101a13:	56                   	push   %esi
f0101a14:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101a1a:	e8 19 fe ff ff       	call   f0101838 <page_insert>
f0101a1f:	83 c4 20             	add    $0x20,%esp
f0101a22:	85 c0                	test   %eax,%eax
f0101a24:	74 19                	je     f0101a3f <check_page+0x1a6>
f0101a26:	68 c8 4b 10 f0       	push   $0xf0104bc8
f0101a2b:	68 7a 50 10 f0       	push   $0xf010507a
f0101a30:	68 46 03 00 00       	push   $0x346
f0101a35:	68 5b 50 10 f0       	push   $0xf010505b
f0101a3a:	e8 6a e6 ff ff       	call   f01000a9 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a3f:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f0101a45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a48:	e8 f0 ef ff ff       	call   f0100a3d <page2pa>
f0101a4d:	8b 17                	mov    (%edi),%edx
f0101a4f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a55:	39 c2                	cmp    %eax,%edx
f0101a57:	74 19                	je     f0101a72 <check_page+0x1d9>
f0101a59:	68 f8 4b 10 f0       	push   $0xf0104bf8
f0101a5e:	68 7a 50 10 f0       	push   $0xf010507a
f0101a63:	68 47 03 00 00       	push   $0x347
f0101a68:	68 5b 50 10 f0       	push   $0xf010505b
f0101a6d:	e8 37 e6 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a72:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a77:	89 f8                	mov    %edi,%eax
f0101a79:	e8 a9 f0 ff ff       	call   f0100b27 <check_va2pa>
f0101a7e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a81:	89 f0                	mov    %esi,%eax
f0101a83:	e8 b5 ef ff ff       	call   f0100a3d <page2pa>
f0101a88:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101a8b:	74 19                	je     f0101aa6 <check_page+0x20d>
f0101a8d:	68 20 4c 10 f0       	push   $0xf0104c20
f0101a92:	68 7a 50 10 f0       	push   $0xf010507a
f0101a97:	68 48 03 00 00       	push   $0x348
f0101a9c:	68 5b 50 10 f0       	push   $0xf010505b
f0101aa1:	e8 03 e6 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0101aa6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aab:	74 19                	je     f0101ac6 <check_page+0x22d>
f0101aad:	68 a7 52 10 f0       	push   $0xf01052a7
f0101ab2:	68 7a 50 10 f0       	push   $0xf010507a
f0101ab7:	68 49 03 00 00       	push   $0x349
f0101abc:	68 5b 50 10 f0       	push   $0xf010505b
f0101ac1:	e8 e3 e5 ff ff       	call   f01000a9 <_panic>
	assert(pp0->pp_ref == 1);
f0101ac6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ace:	74 19                	je     f0101ae9 <check_page+0x250>
f0101ad0:	68 b8 52 10 f0       	push   $0xf01052b8
f0101ad5:	68 7a 50 10 f0       	push   $0xf010507a
f0101ada:	68 4a 03 00 00       	push   $0x34a
f0101adf:	68 5b 50 10 f0       	push   $0xf010505b
f0101ae4:	e8 c0 e5 ff ff       	call   f01000a9 <_panic>
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ae9:	6a 02                	push   $0x2
f0101aeb:	68 00 10 00 00       	push   $0x1000
f0101af0:	53                   	push   %ebx
f0101af1:	57                   	push   %edi
f0101af2:	e8 41 fd ff ff       	call   f0101838 <page_insert>
f0101af7:	83 c4 10             	add    $0x10,%esp
f0101afa:	85 c0                	test   %eax,%eax
f0101afc:	74 19                	je     f0101b17 <check_page+0x27e>
f0101afe:	68 50 4c 10 f0       	push   $0xf0104c50
f0101b03:	68 7a 50 10 f0       	push   $0xf010507a
f0101b08:	68 4c 03 00 00       	push   $0x34c
f0101b0d:	68 5b 50 10 f0       	push   $0xf010505b
f0101b12:	e8 92 e5 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b17:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b1c:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f0101b21:	e8 01 f0 ff ff       	call   f0100b27 <check_va2pa>
f0101b26:	89 c7                	mov    %eax,%edi
f0101b28:	89 d8                	mov    %ebx,%eax
f0101b2a:	e8 0e ef ff ff       	call   f0100a3d <page2pa>
f0101b2f:	39 c7                	cmp    %eax,%edi
f0101b31:	74 19                	je     f0101b4c <check_page+0x2b3>
f0101b33:	68 8c 4c 10 f0       	push   $0xf0104c8c
f0101b38:	68 7a 50 10 f0       	push   $0xf010507a
f0101b3d:	68 4d 03 00 00       	push   $0x34d
f0101b42:	68 5b 50 10 f0       	push   $0xf010505b
f0101b47:	e8 5d e5 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101b4c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b51:	74 19                	je     f0101b6c <check_page+0x2d3>
f0101b53:	68 c9 52 10 f0       	push   $0xf01052c9
f0101b58:	68 7a 50 10 f0       	push   $0xf010507a
f0101b5d:	68 4e 03 00 00       	push   $0x34e
f0101b62:	68 5b 50 10 f0       	push   $0xf010505b
f0101b67:	e8 3d e5 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b6c:	83 ec 0c             	sub    $0xc,%esp
f0101b6f:	6a 00                	push   $0x0
f0101b71:	e8 44 f6 ff ff       	call   f01011ba <page_alloc>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	85 c0                	test   %eax,%eax
f0101b7b:	74 19                	je     f0101b96 <check_page+0x2fd>
f0101b7d:	68 20 52 10 f0       	push   $0xf0105220
f0101b82:	68 7a 50 10 f0       	push   $0xf010507a
f0101b87:	68 51 03 00 00       	push   $0x351
f0101b8c:	68 5b 50 10 f0       	push   $0xf010505b
f0101b91:	e8 13 e5 ff ff       	call   f01000a9 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b96:	6a 02                	push   $0x2
f0101b98:	68 00 10 00 00       	push   $0x1000
f0101b9d:	53                   	push   %ebx
f0101b9e:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101ba4:	e8 8f fc ff ff       	call   f0101838 <page_insert>
f0101ba9:	83 c4 10             	add    $0x10,%esp
f0101bac:	85 c0                	test   %eax,%eax
f0101bae:	74 19                	je     f0101bc9 <check_page+0x330>
f0101bb0:	68 50 4c 10 f0       	push   $0xf0104c50
f0101bb5:	68 7a 50 10 f0       	push   $0xf010507a
f0101bba:	68 54 03 00 00       	push   $0x354
f0101bbf:	68 5b 50 10 f0       	push   $0xf010505b
f0101bc4:	e8 e0 e4 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bce:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f0101bd3:	e8 4f ef ff ff       	call   f0100b27 <check_va2pa>
f0101bd8:	89 c7                	mov    %eax,%edi
f0101bda:	89 d8                	mov    %ebx,%eax
f0101bdc:	e8 5c ee ff ff       	call   f0100a3d <page2pa>
f0101be1:	39 c7                	cmp    %eax,%edi
f0101be3:	74 19                	je     f0101bfe <check_page+0x365>
f0101be5:	68 8c 4c 10 f0       	push   $0xf0104c8c
f0101bea:	68 7a 50 10 f0       	push   $0xf010507a
f0101bef:	68 55 03 00 00       	push   $0x355
f0101bf4:	68 5b 50 10 f0       	push   $0xf010505b
f0101bf9:	e8 ab e4 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101bfe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c03:	74 19                	je     f0101c1e <check_page+0x385>
f0101c05:	68 c9 52 10 f0       	push   $0xf01052c9
f0101c0a:	68 7a 50 10 f0       	push   $0xf010507a
f0101c0f:	68 56 03 00 00       	push   $0x356
f0101c14:	68 5b 50 10 f0       	push   $0xf010505b
f0101c19:	e8 8b e4 ff ff       	call   f01000a9 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c1e:	83 ec 0c             	sub    $0xc,%esp
f0101c21:	6a 00                	push   $0x0
f0101c23:	e8 92 f5 ff ff       	call   f01011ba <page_alloc>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	74 19                	je     f0101c48 <check_page+0x3af>
f0101c2f:	68 20 52 10 f0       	push   $0xf0105220
f0101c34:	68 7a 50 10 f0       	push   $0xf010507a
f0101c39:	68 5a 03 00 00       	push   $0x35a
f0101c3e:	68 5b 50 10 f0       	push   $0xf010505b
f0101c43:	e8 61 e4 ff ff       	call   f01000a9 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c48:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f0101c4e:	8b 0f                	mov    (%edi),%ecx
f0101c50:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101c56:	ba 5d 03 00 00       	mov    $0x35d,%edx
f0101c5b:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0101c60:	e8 78 ee ff ff       	call   f0100add <_kaddr>
f0101c65:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c68:	83 ec 04             	sub    $0x4,%esp
f0101c6b:	6a 00                	push   $0x0
f0101c6d:	68 00 10 00 00       	push   $0x1000
f0101c72:	57                   	push   %edi
f0101c73:	e8 cd f9 ff ff       	call   f0101645 <pgdir_walk>
f0101c78:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101c7b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101c7e:	83 c4 10             	add    $0x10,%esp
f0101c81:	39 d0                	cmp    %edx,%eax
f0101c83:	74 19                	je     f0101c9e <check_page+0x405>
f0101c85:	68 bc 4c 10 f0       	push   $0xf0104cbc
f0101c8a:	68 7a 50 10 f0       	push   $0xf010507a
f0101c8f:	68 5e 03 00 00       	push   $0x35e
f0101c94:	68 5b 50 10 f0       	push   $0xf010505b
f0101c99:	e8 0b e4 ff ff       	call   f01000a9 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c9e:	6a 06                	push   $0x6
f0101ca0:	68 00 10 00 00       	push   $0x1000
f0101ca5:	53                   	push   %ebx
f0101ca6:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101cac:	e8 87 fb ff ff       	call   f0101838 <page_insert>
f0101cb1:	83 c4 10             	add    $0x10,%esp
f0101cb4:	85 c0                	test   %eax,%eax
f0101cb6:	74 19                	je     f0101cd1 <check_page+0x438>
f0101cb8:	68 fc 4c 10 f0       	push   $0xf0104cfc
f0101cbd:	68 7a 50 10 f0       	push   $0xf010507a
f0101cc2:	68 61 03 00 00       	push   $0x361
f0101cc7:	68 5b 50 10 f0       	push   $0xf010505b
f0101ccc:	e8 d8 e3 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cd1:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f0101cd7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cdc:	89 f8                	mov    %edi,%eax
f0101cde:	e8 44 ee ff ff       	call   f0100b27 <check_va2pa>
f0101ce3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ce6:	89 d8                	mov    %ebx,%eax
f0101ce8:	e8 50 ed ff ff       	call   f0100a3d <page2pa>
f0101ced:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101cf0:	74 19                	je     f0101d0b <check_page+0x472>
f0101cf2:	68 8c 4c 10 f0       	push   $0xf0104c8c
f0101cf7:	68 7a 50 10 f0       	push   $0xf010507a
f0101cfc:	68 62 03 00 00       	push   $0x362
f0101d01:	68 5b 50 10 f0       	push   $0xf010505b
f0101d06:	e8 9e e3 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101d0b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d10:	74 19                	je     f0101d2b <check_page+0x492>
f0101d12:	68 c9 52 10 f0       	push   $0xf01052c9
f0101d17:	68 7a 50 10 f0       	push   $0xf010507a
f0101d1c:	68 63 03 00 00       	push   $0x363
f0101d21:	68 5b 50 10 f0       	push   $0xf010505b
f0101d26:	e8 7e e3 ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d2b:	83 ec 04             	sub    $0x4,%esp
f0101d2e:	6a 00                	push   $0x0
f0101d30:	68 00 10 00 00       	push   $0x1000
f0101d35:	57                   	push   %edi
f0101d36:	e8 0a f9 ff ff       	call   f0101645 <pgdir_walk>
f0101d3b:	83 c4 10             	add    $0x10,%esp
f0101d3e:	f6 00 04             	testb  $0x4,(%eax)
f0101d41:	75 19                	jne    f0101d5c <check_page+0x4c3>
f0101d43:	68 3c 4d 10 f0       	push   $0xf0104d3c
f0101d48:	68 7a 50 10 f0       	push   $0xf010507a
f0101d4d:	68 64 03 00 00       	push   $0x364
f0101d52:	68 5b 50 10 f0       	push   $0xf010505b
f0101d57:	e8 4d e3 ff ff       	call   f01000a9 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d5c:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f0101d61:	f6 00 04             	testb  $0x4,(%eax)
f0101d64:	75 19                	jne    f0101d7f <check_page+0x4e6>
f0101d66:	68 da 52 10 f0       	push   $0xf01052da
f0101d6b:	68 7a 50 10 f0       	push   $0xf010507a
f0101d70:	68 65 03 00 00       	push   $0x365
f0101d75:	68 5b 50 10 f0       	push   $0xf010505b
f0101d7a:	e8 2a e3 ff ff       	call   f01000a9 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d7f:	6a 02                	push   $0x2
f0101d81:	68 00 10 00 00       	push   $0x1000
f0101d86:	53                   	push   %ebx
f0101d87:	50                   	push   %eax
f0101d88:	e8 ab fa ff ff       	call   f0101838 <page_insert>
f0101d8d:	83 c4 10             	add    $0x10,%esp
f0101d90:	85 c0                	test   %eax,%eax
f0101d92:	74 19                	je     f0101dad <check_page+0x514>
f0101d94:	68 50 4c 10 f0       	push   $0xf0104c50
f0101d99:	68 7a 50 10 f0       	push   $0xf010507a
f0101d9e:	68 68 03 00 00       	push   $0x368
f0101da3:	68 5b 50 10 f0       	push   $0xf010505b
f0101da8:	e8 fc e2 ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dad:	83 ec 04             	sub    $0x4,%esp
f0101db0:	6a 00                	push   $0x0
f0101db2:	68 00 10 00 00       	push   $0x1000
f0101db7:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101dbd:	e8 83 f8 ff ff       	call   f0101645 <pgdir_walk>
f0101dc2:	83 c4 10             	add    $0x10,%esp
f0101dc5:	f6 00 02             	testb  $0x2,(%eax)
f0101dc8:	75 19                	jne    f0101de3 <check_page+0x54a>
f0101dca:	68 70 4d 10 f0       	push   $0xf0104d70
f0101dcf:	68 7a 50 10 f0       	push   $0xf010507a
f0101dd4:	68 69 03 00 00       	push   $0x369
f0101dd9:	68 5b 50 10 f0       	push   $0xf010505b
f0101dde:	e8 c6 e2 ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101de3:	83 ec 04             	sub    $0x4,%esp
f0101de6:	6a 00                	push   $0x0
f0101de8:	68 00 10 00 00       	push   $0x1000
f0101ded:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101df3:	e8 4d f8 ff ff       	call   f0101645 <pgdir_walk>
f0101df8:	83 c4 10             	add    $0x10,%esp
f0101dfb:	f6 00 04             	testb  $0x4,(%eax)
f0101dfe:	74 19                	je     f0101e19 <check_page+0x580>
f0101e00:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101e05:	68 7a 50 10 f0       	push   $0xf010507a
f0101e0a:	68 6a 03 00 00       	push   $0x36a
f0101e0f:	68 5b 50 10 f0       	push   $0xf010505b
f0101e14:	e8 90 e2 ff ff       	call   f01000a9 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e19:	6a 02                	push   $0x2
f0101e1b:	68 00 00 40 00       	push   $0x400000
f0101e20:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e23:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101e29:	e8 0a fa ff ff       	call   f0101838 <page_insert>
f0101e2e:	83 c4 10             	add    $0x10,%esp
f0101e31:	85 c0                	test   %eax,%eax
f0101e33:	78 19                	js     f0101e4e <check_page+0x5b5>
f0101e35:	68 dc 4d 10 f0       	push   $0xf0104ddc
f0101e3a:	68 7a 50 10 f0       	push   $0xf010507a
f0101e3f:	68 6d 03 00 00       	push   $0x36d
f0101e44:	68 5b 50 10 f0       	push   $0xf010505b
f0101e49:	e8 5b e2 ff ff       	call   f01000a9 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e4e:	6a 02                	push   $0x2
f0101e50:	68 00 10 00 00       	push   $0x1000
f0101e55:	56                   	push   %esi
f0101e56:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101e5c:	e8 d7 f9 ff ff       	call   f0101838 <page_insert>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	85 c0                	test   %eax,%eax
f0101e66:	74 19                	je     f0101e81 <check_page+0x5e8>
f0101e68:	68 14 4e 10 f0       	push   $0xf0104e14
f0101e6d:	68 7a 50 10 f0       	push   $0xf010507a
f0101e72:	68 70 03 00 00       	push   $0x370
f0101e77:	68 5b 50 10 f0       	push   $0xf010505b
f0101e7c:	e8 28 e2 ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e81:	83 ec 04             	sub    $0x4,%esp
f0101e84:	6a 00                	push   $0x0
f0101e86:	68 00 10 00 00       	push   $0x1000
f0101e8b:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101e91:	e8 af f7 ff ff       	call   f0101645 <pgdir_walk>
f0101e96:	83 c4 10             	add    $0x10,%esp
f0101e99:	f6 00 04             	testb  $0x4,(%eax)
f0101e9c:	74 19                	je     f0101eb7 <check_page+0x61e>
f0101e9e:	68 a4 4d 10 f0       	push   $0xf0104da4
f0101ea3:	68 7a 50 10 f0       	push   $0xf010507a
f0101ea8:	68 71 03 00 00       	push   $0x371
f0101ead:	68 5b 50 10 f0       	push   $0xf010505b
f0101eb2:	e8 f2 e1 ff ff       	call   f01000a9 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eb7:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f0101ebd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec2:	89 f8                	mov    %edi,%eax
f0101ec4:	e8 5e ec ff ff       	call   f0100b27 <check_va2pa>
f0101ec9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ecc:	89 f0                	mov    %esi,%eax
f0101ece:	e8 6a eb ff ff       	call   f0100a3d <page2pa>
f0101ed3:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101ed6:	74 19                	je     f0101ef1 <check_page+0x658>
f0101ed8:	68 50 4e 10 f0       	push   $0xf0104e50
f0101edd:	68 7a 50 10 f0       	push   $0xf010507a
f0101ee2:	68 74 03 00 00       	push   $0x374
f0101ee7:	68 5b 50 10 f0       	push   $0xf010505b
f0101eec:	e8 b8 e1 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ef1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ef6:	89 f8                	mov    %edi,%eax
f0101ef8:	e8 2a ec ff ff       	call   f0100b27 <check_va2pa>
f0101efd:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f00:	74 19                	je     f0101f1b <check_page+0x682>
f0101f02:	68 7c 4e 10 f0       	push   $0xf0104e7c
f0101f07:	68 7a 50 10 f0       	push   $0xf010507a
f0101f0c:	68 75 03 00 00       	push   $0x375
f0101f11:	68 5b 50 10 f0       	push   $0xf010505b
f0101f16:	e8 8e e1 ff ff       	call   f01000a9 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f1b:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101f20:	74 19                	je     f0101f3b <check_page+0x6a2>
f0101f22:	68 f0 52 10 f0       	push   $0xf01052f0
f0101f27:	68 7a 50 10 f0       	push   $0xf010507a
f0101f2c:	68 77 03 00 00       	push   $0x377
f0101f31:	68 5b 50 10 f0       	push   $0xf010505b
f0101f36:	e8 6e e1 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f0101f3b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f40:	74 19                	je     f0101f5b <check_page+0x6c2>
f0101f42:	68 01 53 10 f0       	push   $0xf0105301
f0101f47:	68 7a 50 10 f0       	push   $0xf010507a
f0101f4c:	68 78 03 00 00       	push   $0x378
f0101f51:	68 5b 50 10 f0       	push   $0xf010505b
f0101f56:	e8 4e e1 ff ff       	call   f01000a9 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101f5b:	83 ec 0c             	sub    $0xc,%esp
f0101f5e:	6a 00                	push   $0x0
f0101f60:	e8 55 f2 ff ff       	call   f01011ba <page_alloc>
f0101f65:	83 c4 10             	add    $0x10,%esp
f0101f68:	39 c3                	cmp    %eax,%ebx
f0101f6a:	75 04                	jne    f0101f70 <check_page+0x6d7>
f0101f6c:	85 c0                	test   %eax,%eax
f0101f6e:	75 19                	jne    f0101f89 <check_page+0x6f0>
f0101f70:	68 ac 4e 10 f0       	push   $0xf0104eac
f0101f75:	68 7a 50 10 f0       	push   $0xf010507a
f0101f7a:	68 7b 03 00 00       	push   $0x37b
f0101f7f:	68 5b 50 10 f0       	push   $0xf010505b
f0101f84:	e8 20 e1 ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f89:	83 ec 08             	sub    $0x8,%esp
f0101f8c:	6a 00                	push   $0x0
f0101f8e:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0101f94:	e8 59 f8 ff ff       	call   f01017f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f99:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f0101f9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fa4:	89 f8                	mov    %edi,%eax
f0101fa6:	e8 7c eb ff ff       	call   f0100b27 <check_va2pa>
f0101fab:	83 c4 10             	add    $0x10,%esp
f0101fae:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fb1:	74 19                	je     f0101fcc <check_page+0x733>
f0101fb3:	68 d0 4e 10 f0       	push   $0xf0104ed0
f0101fb8:	68 7a 50 10 f0       	push   $0xf010507a
f0101fbd:	68 7f 03 00 00       	push   $0x37f
f0101fc2:	68 5b 50 10 f0       	push   $0xf010505b
f0101fc7:	e8 dd e0 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fcc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fd1:	89 f8                	mov    %edi,%eax
f0101fd3:	e8 4f eb ff ff       	call   f0100b27 <check_va2pa>
f0101fd8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101fdb:	89 f0                	mov    %esi,%eax
f0101fdd:	e8 5b ea ff ff       	call   f0100a3d <page2pa>
f0101fe2:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fe5:	74 19                	je     f0102000 <check_page+0x767>
f0101fe7:	68 7c 4e 10 f0       	push   $0xf0104e7c
f0101fec:	68 7a 50 10 f0       	push   $0xf010507a
f0101ff1:	68 80 03 00 00       	push   $0x380
f0101ff6:	68 5b 50 10 f0       	push   $0xf010505b
f0101ffb:	e8 a9 e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0102000:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102005:	74 19                	je     f0102020 <check_page+0x787>
f0102007:	68 a7 52 10 f0       	push   $0xf01052a7
f010200c:	68 7a 50 10 f0       	push   $0xf010507a
f0102011:	68 81 03 00 00       	push   $0x381
f0102016:	68 5b 50 10 f0       	push   $0xf010505b
f010201b:	e8 89 e0 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f0102020:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102025:	74 19                	je     f0102040 <check_page+0x7a7>
f0102027:	68 01 53 10 f0       	push   $0xf0105301
f010202c:	68 7a 50 10 f0       	push   $0xf010507a
f0102031:	68 82 03 00 00       	push   $0x382
f0102036:	68 5b 50 10 f0       	push   $0xf010505b
f010203b:	e8 69 e0 ff ff       	call   f01000a9 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102040:	6a 00                	push   $0x0
f0102042:	68 00 10 00 00       	push   $0x1000
f0102047:	56                   	push   %esi
f0102048:	57                   	push   %edi
f0102049:	e8 ea f7 ff ff       	call   f0101838 <page_insert>
f010204e:	83 c4 10             	add    $0x10,%esp
f0102051:	85 c0                	test   %eax,%eax
f0102053:	74 19                	je     f010206e <check_page+0x7d5>
f0102055:	68 f4 4e 10 f0       	push   $0xf0104ef4
f010205a:	68 7a 50 10 f0       	push   $0xf010507a
f010205f:	68 85 03 00 00       	push   $0x385
f0102064:	68 5b 50 10 f0       	push   $0xf010505b
f0102069:	e8 3b e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref);
f010206e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102073:	75 19                	jne    f010208e <check_page+0x7f5>
f0102075:	68 12 53 10 f0       	push   $0xf0105312
f010207a:	68 7a 50 10 f0       	push   $0xf010507a
f010207f:	68 86 03 00 00       	push   $0x386
f0102084:	68 5b 50 10 f0       	push   $0xf010505b
f0102089:	e8 1b e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_link == NULL);
f010208e:	83 3e 00             	cmpl   $0x0,(%esi)
f0102091:	74 19                	je     f01020ac <check_page+0x813>
f0102093:	68 1e 53 10 f0       	push   $0xf010531e
f0102098:	68 7a 50 10 f0       	push   $0xf010507a
f010209d:	68 87 03 00 00       	push   $0x387
f01020a2:	68 5b 50 10 f0       	push   $0xf010505b
f01020a7:	e8 fd df ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020ac:	83 ec 08             	sub    $0x8,%esp
f01020af:	68 00 10 00 00       	push   $0x1000
f01020b4:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f01020ba:	e8 33 f7 ff ff       	call   f01017f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020bf:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f01020c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ca:	89 f8                	mov    %edi,%eax
f01020cc:	e8 56 ea ff ff       	call   f0100b27 <check_va2pa>
f01020d1:	83 c4 10             	add    $0x10,%esp
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <check_page+0x859>
f01020d9:	68 d0 4e 10 f0       	push   $0xf0104ed0
f01020de:	68 7a 50 10 f0       	push   $0xf010507a
f01020e3:	68 8b 03 00 00       	push   $0x38b
f01020e8:	68 5b 50 10 f0       	push   $0xf010505b
f01020ed:	e8 b7 df ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020f2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020f7:	89 f8                	mov    %edi,%eax
f01020f9:	e8 29 ea ff ff       	call   f0100b27 <check_va2pa>
f01020fe:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102101:	74 19                	je     f010211c <check_page+0x883>
f0102103:	68 2c 4f 10 f0       	push   $0xf0104f2c
f0102108:	68 7a 50 10 f0       	push   $0xf010507a
f010210d:	68 8c 03 00 00       	push   $0x38c
f0102112:	68 5b 50 10 f0       	push   $0xf010505b
f0102117:	e8 8d df ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f010211c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102121:	74 19                	je     f010213c <check_page+0x8a3>
f0102123:	68 33 53 10 f0       	push   $0xf0105333
f0102128:	68 7a 50 10 f0       	push   $0xf010507a
f010212d:	68 8d 03 00 00       	push   $0x38d
f0102132:	68 5b 50 10 f0       	push   $0xf010505b
f0102137:	e8 6d df ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f010213c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102141:	74 19                	je     f010215c <check_page+0x8c3>
f0102143:	68 01 53 10 f0       	push   $0xf0105301
f0102148:	68 7a 50 10 f0       	push   $0xf010507a
f010214d:	68 8e 03 00 00       	push   $0x38e
f0102152:	68 5b 50 10 f0       	push   $0xf010505b
f0102157:	e8 4d df ff ff       	call   f01000a9 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010215c:	83 ec 0c             	sub    $0xc,%esp
f010215f:	6a 00                	push   $0x0
f0102161:	e8 54 f0 ff ff       	call   f01011ba <page_alloc>
f0102166:	83 c4 10             	add    $0x10,%esp
f0102169:	39 c6                	cmp    %eax,%esi
f010216b:	75 04                	jne    f0102171 <check_page+0x8d8>
f010216d:	85 c0                	test   %eax,%eax
f010216f:	75 19                	jne    f010218a <check_page+0x8f1>
f0102171:	68 54 4f 10 f0       	push   $0xf0104f54
f0102176:	68 7a 50 10 f0       	push   $0xf010507a
f010217b:	68 91 03 00 00       	push   $0x391
f0102180:	68 5b 50 10 f0       	push   $0xf010505b
f0102185:	e8 1f df ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010218a:	83 ec 0c             	sub    $0xc,%esp
f010218d:	6a 00                	push   $0x0
f010218f:	e8 26 f0 ff ff       	call   f01011ba <page_alloc>
f0102194:	83 c4 10             	add    $0x10,%esp
f0102197:	85 c0                	test   %eax,%eax
f0102199:	74 19                	je     f01021b4 <check_page+0x91b>
f010219b:	68 20 52 10 f0       	push   $0xf0105220
f01021a0:	68 7a 50 10 f0       	push   $0xf010507a
f01021a5:	68 94 03 00 00       	push   $0x394
f01021aa:	68 5b 50 10 f0       	push   $0xf010505b
f01021af:	e8 f5 de ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021b4:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f01021ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021bd:	e8 7b e8 ff ff       	call   f0100a3d <page2pa>
f01021c2:	8b 17                	mov    (%edi),%edx
f01021c4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021ca:	39 c2                	cmp    %eax,%edx
f01021cc:	74 19                	je     f01021e7 <check_page+0x94e>
f01021ce:	68 f8 4b 10 f0       	push   $0xf0104bf8
f01021d3:	68 7a 50 10 f0       	push   $0xf010507a
f01021d8:	68 97 03 00 00       	push   $0x397
f01021dd:	68 5b 50 10 f0       	push   $0xf010505b
f01021e2:	e8 c2 de ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f01021e7:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01021ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021f5:	74 19                	je     f0102210 <check_page+0x977>
f01021f7:	68 b8 52 10 f0       	push   $0xf01052b8
f01021fc:	68 7a 50 10 f0       	push   $0xf010507a
f0102201:	68 99 03 00 00       	push   $0x399
f0102206:	68 5b 50 10 f0       	push   $0xf010505b
f010220b:	e8 99 de ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f0102210:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102213:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102219:	83 ec 0c             	sub    $0xc,%esp
f010221c:	50                   	push   %eax
f010221d:	e8 dd ef ff ff       	call   f01011ff <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102222:	83 c4 0c             	add    $0xc,%esp
f0102225:	6a 01                	push   $0x1
f0102227:	68 00 10 40 00       	push   $0x401000
f010222c:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0102232:	e8 0e f4 ff ff       	call   f0101645 <pgdir_walk>
f0102237:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010223a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010223d:	8b 3d a8 6a 19 f0    	mov    0xf0196aa8,%edi
f0102243:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102246:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010224c:	ba a0 03 00 00       	mov    $0x3a0,%edx
f0102251:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0102256:	e8 82 e8 ff ff       	call   f0100add <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f010225b:	83 c0 04             	add    $0x4,%eax
f010225e:	83 c4 10             	add    $0x10,%esp
f0102261:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102264:	74 19                	je     f010227f <check_page+0x9e6>
f0102266:	68 44 53 10 f0       	push   $0xf0105344
f010226b:	68 7a 50 10 f0       	push   $0xf010507a
f0102270:	68 a1 03 00 00       	push   $0x3a1
f0102275:	68 5b 50 10 f0       	push   $0xf010505b
f010227a:	e8 2a de ff ff       	call   f01000a9 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010227f:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	pp0->pp_ref = 0;
f0102286:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102289:	89 f8                	mov    %edi,%eax
f010228b:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102291:	e8 73 e8 ff ff       	call   f0100b09 <page2kva>
f0102296:	83 ec 04             	sub    $0x4,%esp
f0102299:	68 00 10 00 00       	push   $0x1000
f010229e:	68 ff 00 00 00       	push   $0xff
f01022a3:	50                   	push   %eax
f01022a4:	e8 da 1b 00 00       	call   f0103e83 <memset>
	page_free(pp0);
f01022a9:	89 3c 24             	mov    %edi,(%esp)
f01022ac:	e8 4e ef ff ff       	call   f01011ff <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022b1:	83 c4 0c             	add    $0xc,%esp
f01022b4:	6a 01                	push   $0x1
f01022b6:	6a 00                	push   $0x0
f01022b8:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f01022be:	e8 82 f3 ff ff       	call   f0101645 <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f01022c3:	89 f8                	mov    %edi,%eax
f01022c5:	e8 3f e8 ff ff       	call   f0100b09 <page2kva>
f01022ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022cd:	89 c2                	mov    %eax,%edx
f01022cf:	05 00 10 00 00       	add    $0x1000,%eax
f01022d4:	83 c4 10             	add    $0x10,%esp
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022d7:	f6 02 01             	testb  $0x1,(%edx)
f01022da:	74 19                	je     f01022f5 <check_page+0xa5c>
f01022dc:	68 5c 53 10 f0       	push   $0xf010535c
f01022e1:	68 7a 50 10 f0       	push   $0xf010507a
f01022e6:	68 ab 03 00 00       	push   $0x3ab
f01022eb:	68 5b 50 10 f0       	push   $0xf010505b
f01022f0:	e8 b4 dd ff ff       	call   f01000a9 <_panic>
f01022f5:	83 c2 04             	add    $0x4,%edx
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01022f8:	39 c2                	cmp    %eax,%edx
f01022fa:	75 db                	jne    f01022d7 <check_page+0xa3e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01022fc:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f0102301:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102307:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010230a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102310:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102313:	89 0d dc 4d 19 f0    	mov    %ecx,0xf0194ddc

	// free the pages we took
	page_free(pp0);
f0102319:	83 ec 0c             	sub    $0xc,%esp
f010231c:	50                   	push   %eax
f010231d:	e8 dd ee ff ff       	call   f01011ff <page_free>
	page_free(pp1);
f0102322:	89 34 24             	mov    %esi,(%esp)
f0102325:	e8 d5 ee ff ff       	call   f01011ff <page_free>
	page_free(pp2);
f010232a:	89 1c 24             	mov    %ebx,(%esp)
f010232d:	e8 cd ee ff ff       	call   f01011ff <page_free>

	cprintf("check_page() succeeded!\n");
f0102332:	c7 04 24 73 53 10 f0 	movl   $0xf0105373,(%esp)
f0102339:	e8 91 0c 00 00       	call   f0102fcf <cprintf>
}
f010233e:	83 c4 10             	add    $0x10,%esp
f0102341:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102344:	5b                   	pop    %ebx
f0102345:	5e                   	pop    %esi
f0102346:	5f                   	pop    %edi
f0102347:	5d                   	pop    %ebp
f0102348:	c3                   	ret    

f0102349 <check_page_installed_pgdir>:

// check page_insert, page_remove, &c, with an installed kern_pgdir
static void
check_page_installed_pgdir(void)
{
f0102349:	55                   	push   %ebp
f010234a:	89 e5                	mov    %esp,%ebp
f010234c:	57                   	push   %edi
f010234d:	56                   	push   %esi
f010234e:	53                   	push   %ebx
f010234f:	83 ec 18             	sub    $0x18,%esp
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102352:	6a 00                	push   $0x0
f0102354:	e8 61 ee ff ff       	call   f01011ba <page_alloc>
f0102359:	83 c4 10             	add    $0x10,%esp
f010235c:	85 c0                	test   %eax,%eax
f010235e:	75 19                	jne    f0102379 <check_page_installed_pgdir+0x30>
f0102360:	68 75 51 10 f0       	push   $0xf0105175
f0102365:	68 7a 50 10 f0       	push   $0xf010507a
f010236a:	68 c6 03 00 00       	push   $0x3c6
f010236f:	68 5b 50 10 f0       	push   $0xf010505b
f0102374:	e8 30 dd ff ff       	call   f01000a9 <_panic>
f0102379:	89 c6                	mov    %eax,%esi
	assert((pp1 = page_alloc(0)));
f010237b:	83 ec 0c             	sub    $0xc,%esp
f010237e:	6a 00                	push   $0x0
f0102380:	e8 35 ee ff ff       	call   f01011ba <page_alloc>
f0102385:	89 c7                	mov    %eax,%edi
f0102387:	83 c4 10             	add    $0x10,%esp
f010238a:	85 c0                	test   %eax,%eax
f010238c:	75 19                	jne    f01023a7 <check_page_installed_pgdir+0x5e>
f010238e:	68 8b 51 10 f0       	push   $0xf010518b
f0102393:	68 7a 50 10 f0       	push   $0xf010507a
f0102398:	68 c7 03 00 00       	push   $0x3c7
f010239d:	68 5b 50 10 f0       	push   $0xf010505b
f01023a2:	e8 02 dd ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01023a7:	83 ec 0c             	sub    $0xc,%esp
f01023aa:	6a 00                	push   $0x0
f01023ac:	e8 09 ee ff ff       	call   f01011ba <page_alloc>
f01023b1:	89 c3                	mov    %eax,%ebx
f01023b3:	83 c4 10             	add    $0x10,%esp
f01023b6:	85 c0                	test   %eax,%eax
f01023b8:	75 19                	jne    f01023d3 <check_page_installed_pgdir+0x8a>
f01023ba:	68 a1 51 10 f0       	push   $0xf01051a1
f01023bf:	68 7a 50 10 f0       	push   $0xf010507a
f01023c4:	68 c8 03 00 00       	push   $0x3c8
f01023c9:	68 5b 50 10 f0       	push   $0xf010505b
f01023ce:	e8 d6 dc ff ff       	call   f01000a9 <_panic>
	page_free(pp0);
f01023d3:	83 ec 0c             	sub    $0xc,%esp
f01023d6:	56                   	push   %esi
f01023d7:	e8 23 ee ff ff       	call   f01011ff <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f01023dc:	89 f8                	mov    %edi,%eax
f01023de:	e8 26 e7 ff ff       	call   f0100b09 <page2kva>
f01023e3:	83 c4 0c             	add    $0xc,%esp
f01023e6:	68 00 10 00 00       	push   $0x1000
f01023eb:	6a 01                	push   $0x1
f01023ed:	50                   	push   %eax
f01023ee:	e8 90 1a 00 00       	call   f0103e83 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01023f3:	89 d8                	mov    %ebx,%eax
f01023f5:	e8 0f e7 ff ff       	call   f0100b09 <page2kva>
f01023fa:	83 c4 0c             	add    $0xc,%esp
f01023fd:	68 00 10 00 00       	push   $0x1000
f0102402:	6a 02                	push   $0x2
f0102404:	50                   	push   %eax
f0102405:	e8 79 1a 00 00       	call   f0103e83 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010240a:	6a 02                	push   $0x2
f010240c:	68 00 10 00 00       	push   $0x1000
f0102411:	57                   	push   %edi
f0102412:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0102418:	e8 1b f4 ff ff       	call   f0101838 <page_insert>
	assert(pp1->pp_ref == 1);
f010241d:	83 c4 20             	add    $0x20,%esp
f0102420:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102425:	74 19                	je     f0102440 <check_page_installed_pgdir+0xf7>
f0102427:	68 a7 52 10 f0       	push   $0xf01052a7
f010242c:	68 7a 50 10 f0       	push   $0xf010507a
f0102431:	68 cd 03 00 00       	push   $0x3cd
f0102436:	68 5b 50 10 f0       	push   $0xf010505b
f010243b:	e8 69 dc ff ff       	call   f01000a9 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102440:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102447:	01 01 01 
f010244a:	74 19                	je     f0102465 <check_page_installed_pgdir+0x11c>
f010244c:	68 78 4f 10 f0       	push   $0xf0104f78
f0102451:	68 7a 50 10 f0       	push   $0xf010507a
f0102456:	68 ce 03 00 00       	push   $0x3ce
f010245b:	68 5b 50 10 f0       	push   $0xf010505b
f0102460:	e8 44 dc ff ff       	call   f01000a9 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102465:	6a 02                	push   $0x2
f0102467:	68 00 10 00 00       	push   $0x1000
f010246c:	53                   	push   %ebx
f010246d:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0102473:	e8 c0 f3 ff ff       	call   f0101838 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102478:	83 c4 10             	add    $0x10,%esp
f010247b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102482:	02 02 02 
f0102485:	74 19                	je     f01024a0 <check_page_installed_pgdir+0x157>
f0102487:	68 9c 4f 10 f0       	push   $0xf0104f9c
f010248c:	68 7a 50 10 f0       	push   $0xf010507a
f0102491:	68 d0 03 00 00       	push   $0x3d0
f0102496:	68 5b 50 10 f0       	push   $0xf010505b
f010249b:	e8 09 dc ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f01024a0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024a5:	74 19                	je     f01024c0 <check_page_installed_pgdir+0x177>
f01024a7:	68 c9 52 10 f0       	push   $0xf01052c9
f01024ac:	68 7a 50 10 f0       	push   $0xf010507a
f01024b1:	68 d1 03 00 00       	push   $0x3d1
f01024b6:	68 5b 50 10 f0       	push   $0xf010505b
f01024bb:	e8 e9 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f01024c0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024c5:	74 19                	je     f01024e0 <check_page_installed_pgdir+0x197>
f01024c7:	68 33 53 10 f0       	push   $0xf0105333
f01024cc:	68 7a 50 10 f0       	push   $0xf010507a
f01024d1:	68 d2 03 00 00       	push   $0x3d2
f01024d6:	68 5b 50 10 f0       	push   $0xf010505b
f01024db:	e8 c9 db ff ff       	call   f01000a9 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024e0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024e7:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024ea:	89 d8                	mov    %ebx,%eax
f01024ec:	e8 18 e6 ff ff       	call   f0100b09 <page2kva>
f01024f1:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01024f7:	74 19                	je     f0102512 <check_page_installed_pgdir+0x1c9>
f01024f9:	68 c0 4f 10 f0       	push   $0xf0104fc0
f01024fe:	68 7a 50 10 f0       	push   $0xf010507a
f0102503:	68 d4 03 00 00       	push   $0x3d4
f0102508:	68 5b 50 10 f0       	push   $0xf010505b
f010250d:	e8 97 db ff ff       	call   f01000a9 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102512:	83 ec 08             	sub    $0x8,%esp
f0102515:	68 00 10 00 00       	push   $0x1000
f010251a:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0102520:	e8 cd f2 ff ff       	call   f01017f2 <page_remove>
	assert(pp2->pp_ref == 0);
f0102525:	83 c4 10             	add    $0x10,%esp
f0102528:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010252d:	74 19                	je     f0102548 <check_page_installed_pgdir+0x1ff>
f010252f:	68 01 53 10 f0       	push   $0xf0105301
f0102534:	68 7a 50 10 f0       	push   $0xf010507a
f0102539:	68 d6 03 00 00       	push   $0x3d6
f010253e:	68 5b 50 10 f0       	push   $0xf010505b
f0102543:	e8 61 db ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102548:	8b 1d a8 6a 19 f0    	mov    0xf0196aa8,%ebx
f010254e:	89 f0                	mov    %esi,%eax
f0102550:	e8 e8 e4 ff ff       	call   f0100a3d <page2pa>
f0102555:	8b 13                	mov    (%ebx),%edx
f0102557:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010255d:	39 c2                	cmp    %eax,%edx
f010255f:	74 19                	je     f010257a <check_page_installed_pgdir+0x231>
f0102561:	68 f8 4b 10 f0       	push   $0xf0104bf8
f0102566:	68 7a 50 10 f0       	push   $0xf010507a
f010256b:	68 d9 03 00 00       	push   $0x3d9
f0102570:	68 5b 50 10 f0       	push   $0xf010505b
f0102575:	e8 2f db ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f010257a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102580:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102585:	74 19                	je     f01025a0 <check_page_installed_pgdir+0x257>
f0102587:	68 b8 52 10 f0       	push   $0xf01052b8
f010258c:	68 7a 50 10 f0       	push   $0xf010507a
f0102591:	68 db 03 00 00       	push   $0x3db
f0102596:	68 5b 50 10 f0       	push   $0xf010505b
f010259b:	e8 09 db ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f01025a0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01025a6:	83 ec 0c             	sub    $0xc,%esp
f01025a9:	56                   	push   %esi
f01025aa:	e8 50 ec ff ff       	call   f01011ff <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025af:	c7 04 24 ec 4f 10 f0 	movl   $0xf0104fec,(%esp)
f01025b6:	e8 14 0a 00 00       	call   f0102fcf <cprintf>
}
f01025bb:	83 c4 10             	add    $0x10,%esp
f01025be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01025c1:	5b                   	pop    %ebx
f01025c2:	5e                   	pop    %esi
f01025c3:	5f                   	pop    %edi
f01025c4:	5d                   	pop    %ebp
f01025c5:	c3                   	ret    

f01025c6 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01025c6:	55                   	push   %ebp
f01025c7:	89 e5                	mov    %esp,%ebp
f01025c9:	53                   	push   %ebx
f01025ca:	83 ec 04             	sub    $0x4,%esp
	uint32_t cr0;
	size_t n;

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();
f01025cd:	e8 a5 e4 ff ff       	call   f0100a77 <i386_detect_memory>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01025d2:	b8 00 10 00 00       	mov    $0x1000,%eax
f01025d7:	e8 dd e5 ff ff       	call   f0100bb9 <boot_alloc>
f01025dc:	a3 a8 6a 19 f0       	mov    %eax,0xf0196aa8
	memset(kern_pgdir, 0, PGSIZE);
f01025e1:	83 ec 04             	sub    $0x4,%esp
f01025e4:	68 00 10 00 00       	push   $0x1000
f01025e9:	6a 00                	push   $0x0
f01025eb:	50                   	push   %eax
f01025ec:	e8 92 18 00 00       	call   f0103e83 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01025f1:	8b 1d a8 6a 19 f0    	mov    0xf0196aa8,%ebx
f01025f7:	89 d9                	mov    %ebx,%ecx
f01025f9:	ba 93 00 00 00       	mov    $0x93,%edx
f01025fe:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0102603:	e8 8f e5 ff ff       	call   f0100b97 <_paddr>
f0102608:	83 c8 05             	or     $0x5,%eax
f010260b:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102611:	a1 a4 6a 19 f0       	mov    0xf0196aa4,%eax
f0102616:	c1 e0 03             	shl    $0x3,%eax
f0102619:	e8 9b e5 ff ff       	call   f0100bb9 <boot_alloc>
f010261e:	a3 ac 6a 19 f0       	mov    %eax,0xf0196aac
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102623:	83 c4 0c             	add    $0xc,%esp
f0102626:	8b 1d a4 6a 19 f0    	mov    0xf0196aa4,%ebx
f010262c:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102633:	52                   	push   %edx
f0102634:	6a 00                	push   $0x0
f0102636:	50                   	push   %eax
f0102637:	e8 47 18 00 00       	call   f0103e83 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f010263c:	b8 00 80 01 00       	mov    $0x18000,%eax
f0102641:	e8 73 e5 ff ff       	call   f0100bb9 <boot_alloc>
f0102646:	a3 e4 4d 19 f0       	mov    %eax,0xf0194de4
	memset(envs,0, NENV*sizeof(struct Env));
f010264b:	83 c4 0c             	add    $0xc,%esp
f010264e:	68 00 80 01 00       	push   $0x18000
f0102653:	6a 00                	push   $0x0
f0102655:	50                   	push   %eax
f0102656:	e8 28 18 00 00       	call   f0103e83 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010265b:	e8 dc ea ff ff       	call   f010113c <page_init>

	check_page_free_list(1);
f0102660:	b8 01 00 00 00       	mov    $0x1,%eax
f0102665:	e8 2e e8 ff ff       	call   f0100e98 <check_page_free_list>
	check_page_alloc();
f010266a:	e8 e2 eb ff ff       	call   f0101251 <check_page_alloc>
	check_page();
f010266f:	e8 25 f2 ff ff       	call   f0101899 <check_page>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,UPAGES,npages*sizeof(struct PageInfo),PADDR(pages),PTE_U|PTE_P);
f0102674:	8b 0d ac 6a 19 f0    	mov    0xf0196aac,%ecx
f010267a:	ba bd 00 00 00       	mov    $0xbd,%edx
f010267f:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0102684:	e8 0e e5 ff ff       	call   f0100b97 <_paddr>
f0102689:	8b 1d a4 6a 19 f0    	mov    0xf0196aa4,%ebx
f010268f:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102696:	83 c4 08             	add    $0x8,%esp
f0102699:	6a 05                	push   $0x5
f010269b:	50                   	push   %eax
f010269c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026a1:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f01026a6:	e8 39 f0 ff ff       	call   f01016e4 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f01026ab:	8b 0d e4 4d 19 f0    	mov    0xf0194de4,%ecx
f01026b1:	ba c5 00 00 00       	mov    $0xc5,%edx
f01026b6:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f01026bb:	e8 d7 e4 ff ff       	call   f0100b97 <_paddr>
f01026c0:	83 c4 08             	add    $0x8,%esp
f01026c3:	6a 05                	push   $0x5
f01026c5:	50                   	push   %eax
f01026c6:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01026cb:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01026d0:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f01026d5:	e8 0a f0 ff ff       	call   f01016e4 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f01026da:	b9 00 60 10 f0       	mov    $0xf0106000,%ecx
f01026df:	ba d2 00 00 00       	mov    $0xd2,%edx
f01026e4:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f01026e9:	e8 a9 e4 ff ff       	call   f0100b97 <_paddr>
f01026ee:	83 c4 08             	add    $0x8,%esp
f01026f1:	6a 03                	push   $0x3
f01026f3:	50                   	push   %eax
f01026f4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026f9:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026fe:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f0102703:	e8 dc ef ff ff       	call   f01016e4 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KERNBASE,~0x0-KERNBASE+1,0,PTE_P|PTE_W);
f0102708:	83 c4 08             	add    $0x8,%esp
f010270b:	6a 03                	push   $0x3
f010270d:	6a 00                	push   $0x0
f010270f:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102714:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102719:	a1 a8 6a 19 f0       	mov    0xf0196aa8,%eax
f010271e:	e8 c1 ef ff ff       	call   f01016e4 <boot_map_region>
	// Check that the initial page directory has been set up correctly.
	check_kern_pgdir();
f0102723:	e8 0d e5 ff ff       	call   f0100c35 <check_kern_pgdir>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102728:	8b 0d a8 6a 19 f0    	mov    0xf0196aa8,%ecx
f010272e:	ba e7 00 00 00       	mov    $0xe7,%edx
f0102733:	b8 5b 50 10 f0       	mov    $0xf010505b,%eax
f0102738:	e8 5a e4 ff ff       	call   f0100b97 <_paddr>
f010273d:	e8 f3 e2 ff ff       	call   f0100a35 <lcr3>

	check_page_free_list(0);
f0102742:	b8 00 00 00 00       	mov    $0x0,%eax
f0102747:	e8 4c e7 ff ff       	call   f0100e98 <check_page_free_list>

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
f010274c:	e8 dc e2 ff ff       	call   f0100a2d <rcr0>
f0102751:	83 e0 f3             	and    $0xfffffff3,%eax
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);
f0102754:	0d 23 00 05 80       	or     $0x80050023,%eax
f0102759:	e8 c7 e2 ff ff       	call   f0100a25 <lcr0>

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
f010275e:	e8 e6 fb ff ff       	call   f0102349 <check_page_installed_pgdir>
}
f0102763:	83 c4 10             	add    $0x10,%esp
f0102766:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102769:	c9                   	leave  
f010276a:	c3                   	ret    

f010276b <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f010276b:	55                   	push   %ebp
f010276c:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f010276e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102773:	5d                   	pop    %ebp
f0102774:	c3                   	ret    

f0102775 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102775:	55                   	push   %ebp
f0102776:	89 e5                	mov    %esp,%ebp
f0102778:	53                   	push   %ebx
f0102779:	83 ec 04             	sub    $0x4,%esp
f010277c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f010277f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102782:	83 c8 04             	or     $0x4,%eax
f0102785:	50                   	push   %eax
f0102786:	ff 75 10             	pushl  0x10(%ebp)
f0102789:	ff 75 0c             	pushl  0xc(%ebp)
f010278c:	53                   	push   %ebx
f010278d:	e8 d9 ff ff ff       	call   f010276b <user_mem_check>
f0102792:	83 c4 10             	add    $0x10,%esp
f0102795:	85 c0                	test   %eax,%eax
f0102797:	79 1d                	jns    f01027b6 <user_mem_assert+0x41>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102799:	83 ec 04             	sub    $0x4,%esp
f010279c:	6a 00                	push   $0x0
f010279e:	ff 73 48             	pushl  0x48(%ebx)
f01027a1:	68 18 50 10 f0       	push   $0xf0105018
f01027a6:	e8 24 08 00 00       	call   f0102fcf <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01027ab:	89 1c 24             	mov    %ebx,(%esp)
f01027ae:	e8 ab 06 00 00       	call   f0102e5e <env_destroy>
f01027b3:	83 c4 10             	add    $0x10,%esp
	}
}
f01027b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01027b9:	c9                   	leave  
f01027ba:	c3                   	ret    

f01027bb <lgdt>:
	asm volatile("lidt (%0)" : : "r" (p));
}

static inline void
lgdt(void *p)
{
f01027bb:	55                   	push   %ebp
f01027bc:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f01027be:	0f 01 10             	lgdtl  (%eax)
}
f01027c1:	5d                   	pop    %ebp
f01027c2:	c3                   	ret    

f01027c3 <lldt>:

static inline void
lldt(uint16_t sel)
{
f01027c3:	55                   	push   %ebp
f01027c4:	89 e5                	mov    %esp,%ebp
	asm volatile("lldt %0" : : "r" (sel));
f01027c6:	0f 00 d0             	lldt   %ax
}
f01027c9:	5d                   	pop    %ebp
f01027ca:	c3                   	ret    

f01027cb <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f01027cb:	55                   	push   %ebp
f01027cc:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01027ce:	0f 22 d8             	mov    %eax,%cr3
}
f01027d1:	5d                   	pop    %ebp
f01027d2:	c3                   	ret    

f01027d3 <rcr3>:

static inline uint32_t
rcr3(void)
{
f01027d3:	55                   	push   %ebp
f01027d4:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr3,%0" : "=r" (val));
f01027d6:	0f 20 d8             	mov    %cr3,%eax
	return val;
}
f01027d9:	5d                   	pop    %ebp
f01027da:	c3                   	ret    

f01027db <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f01027db:	55                   	push   %ebp
f01027dc:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f01027de:	2b 05 ac 6a 19 f0    	sub    0xf0196aac,%eax
f01027e4:	c1 f8 03             	sar    $0x3,%eax
f01027e7:	c1 e0 0c             	shl    $0xc,%eax
}
f01027ea:	5d                   	pop    %ebp
f01027eb:	c3                   	ret    

f01027ec <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f01027ec:	55                   	push   %ebp
f01027ed:	89 e5                	mov    %esp,%ebp
f01027ef:	53                   	push   %ebx
f01027f0:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f01027f3:	89 cb                	mov    %ecx,%ebx
f01027f5:	c1 eb 0c             	shr    $0xc,%ebx
f01027f8:	3b 1d a4 6a 19 f0    	cmp    0xf0196aa4,%ebx
f01027fe:	72 0d                	jb     f010280d <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102800:	51                   	push   %ecx
f0102801:	68 a0 48 10 f0       	push   $0xf01048a0
f0102806:	52                   	push   %edx
f0102807:	50                   	push   %eax
f0102808:	e8 9c d8 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f010280d:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f0102813:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102816:	c9                   	leave  
f0102817:	c3                   	ret    

f0102818 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0102818:	55                   	push   %ebp
f0102819:	89 e5                	mov    %esp,%ebp
f010281b:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f010281e:	e8 b8 ff ff ff       	call   f01027db <page2pa>
f0102823:	89 c1                	mov    %eax,%ecx
f0102825:	ba 56 00 00 00       	mov    $0x56,%edx
f010282a:	b8 4d 50 10 f0       	mov    $0xf010504d,%eax
f010282f:	e8 b8 ff ff ff       	call   f01027ec <_kaddr>
}
f0102834:	c9                   	leave  
f0102835:	c3                   	ret    

f0102836 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102836:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f010283c:	77 13                	ja     f0102851 <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f010283e:	55                   	push   %ebp
f010283f:	89 e5                	mov    %esp,%ebp
f0102841:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102844:	51                   	push   %ecx
f0102845:	68 c4 48 10 f0       	push   $0xf01048c4
f010284a:	52                   	push   %edx
f010284b:	50                   	push   %eax
f010284c:	e8 58 d8 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102851:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f0102857:	c3                   	ret    

f0102858 <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f0102858:	55                   	push   %ebp
f0102859:	89 e5                	mov    %esp,%ebp
f010285b:	56                   	push   %esi
f010285c:	53                   	push   %ebx
f010285d:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f010285f:	83 ec 0c             	sub    $0xc,%esp
f0102862:	6a 01                	push   $0x1
f0102864:	e8 51 e9 ff ff       	call   f01011ba <page_alloc>
f0102869:	83 c4 10             	add    $0x10,%esp
f010286c:	85 c0                	test   %eax,%eax
f010286e:	74 4a                	je     f01028ba <env_setup_vm+0x62>
f0102870:	89 c3                	mov    %eax,%ebx
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	e->env_pgdir = page2kva(p);
f0102872:	e8 a1 ff ff ff       	call   f0102818 <page2kva>
f0102877:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f010287a:	83 ec 04             	sub    $0x4,%esp
f010287d:	68 00 10 00 00       	push   $0x1000
f0102882:	ff 35 a8 6a 19 f0    	pushl  0xf0196aa8
f0102888:	50                   	push   %eax
f0102889:	e8 ab 16 00 00       	call   f0103f39 <memcpy>
	p->pp_ref ++;
f010288e:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102893:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102896:	89 d9                	mov    %ebx,%ecx
f0102898:	ba c2 00 00 00       	mov    $0xc2,%edx
f010289d:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f01028a2:	e8 8f ff ff ff       	call   f0102836 <_paddr>
f01028a7:	83 c8 05             	or     $0x5,%eax
f01028aa:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f01028b0:	83 c4 10             	add    $0x10,%esp
f01028b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01028b8:	eb 05                	jmp    f01028bf <env_setup_vm+0x67>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01028ba:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f01028bf:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01028c2:	5b                   	pop    %ebx
f01028c3:	5e                   	pop    %esi
f01028c4:	5d                   	pop    %ebp
f01028c5:	c3                   	ret    

f01028c6 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028c6:	c1 e8 0c             	shr    $0xc,%eax
f01028c9:	3b 05 a4 6a 19 f0    	cmp    0xf0196aa4,%eax
f01028cf:	72 17                	jb     f01028e8 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f01028d1:	55                   	push   %ebp
f01028d2:	89 e5                	mov    %esp,%ebp
f01028d4:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f01028d7:	68 d4 4a 10 f0       	push   $0xf0104ad4
f01028dc:	6a 4f                	push   $0x4f
f01028de:	68 4d 50 10 f0       	push   $0xf010504d
f01028e3:	e8 c1 d7 ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f01028e8:	8b 15 ac 6a 19 f0    	mov    0xf0196aac,%edx
f01028ee:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01028f1:	c3                   	ret    

f01028f2 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01028f2:	55                   	push   %ebp
f01028f3:	89 e5                	mov    %esp,%ebp
f01028f5:	57                   	push   %edi
f01028f6:	56                   	push   %esi
f01028f7:	53                   	push   %ebx
f01028f8:	83 ec 1c             	sub    $0x1c,%esp
f01028fb:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	va = ROUNDDOWN(va,PGSIZE);
f01028fd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102903:	89 d6                	mov    %edx,%esi
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f0102905:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f010290c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102911:	89 c1                	mov    %eax,%ecx
f0102913:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (va_finish>va) {
		len = va_finish - va; //es un multiplo de PGSIZE	
f0102916:	29 d0                	sub    %edx,%eax
f0102918:	89 d3                	mov    %edx,%ebx
f010291a:	f7 db                	neg    %ebx
f010291c:	39 ca                	cmp    %ecx,%edx
f010291e:	0f 42 d8             	cmovb  %eax,%ebx
f0102921:	eb 5f                	jmp    f0102982 <region_alloc+0x90>
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	while (len>0){
		struct PageInfo* page = page_alloc(0);//no hay que inicializar
f0102923:	83 ec 0c             	sub    $0xc,%esp
f0102926:	6a 00                	push   $0x0
f0102928:	e8 8d e8 ff ff       	call   f01011ba <page_alloc>
		if (page == NULL) panic("Error allocating environment");
f010292d:	83 c4 10             	add    $0x10,%esp
f0102930:	85 c0                	test   %eax,%eax
f0102932:	75 17                	jne    f010294b <region_alloc+0x59>
f0102934:	83 ec 04             	sub    $0x4,%esp
f0102937:	68 cd 53 10 f0       	push   $0xf01053cd
f010293c:	68 22 01 00 00       	push   $0x122
f0102941:	68 c2 53 10 f0       	push   $0xf01053c2
f0102946:	e8 5e d7 ff ff       	call   f01000a9 <_panic>

		int ret_code = page_insert(e->env_pgdir, page, va, PTE_W | PTE_U);
f010294b:	6a 06                	push   $0x6
f010294d:	56                   	push   %esi
f010294e:	50                   	push   %eax
f010294f:	ff 77 5c             	pushl  0x5c(%edi)
f0102952:	e8 e1 ee ff ff       	call   f0101838 <page_insert>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
f0102957:	83 c4 10             	add    $0x10,%esp
f010295a:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010295d:	75 17                	jne    f0102976 <region_alloc+0x84>
f010295f:	83 ec 04             	sub    $0x4,%esp
f0102962:	68 cd 53 10 f0       	push   $0xf01053cd
f0102967:	68 25 01 00 00       	push   $0x125
f010296c:	68 c2 53 10 f0       	push   $0xf01053c2
f0102971:	e8 33 d7 ff ff       	call   f01000a9 <_panic>
		
		va+=PGSIZE;
f0102976:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len-=PGSIZE;
f010297c:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
		len = va_finish - va; //es un multiplo de PGSIZE	
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	while (len>0){
f0102982:	85 db                	test   %ebx,%ebx
f0102984:	75 9d                	jne    f0102923 <region_alloc+0x31>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
		
		va+=PGSIZE;
		len-=PGSIZE;
	}
	assert(va==va_finish);
f0102986:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0102989:	74 19                	je     f01029a4 <region_alloc+0xb2>
f010298b:	68 ea 53 10 f0       	push   $0xf01053ea
f0102990:	68 7a 50 10 f0       	push   $0xf010507a
f0102995:	68 2a 01 00 00       	push   $0x12a
f010299a:	68 c2 53 10 f0       	push   $0xf01053c2
f010299f:	e8 05 d7 ff ff       	call   f01000a9 <_panic>
}
f01029a4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01029a7:	5b                   	pop    %ebx
f01029a8:	5e                   	pop    %esi
f01029a9:	5f                   	pop    %edi
f01029aa:	5d                   	pop    %ebp
f01029ab:	c3                   	ret    

f01029ac <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f01029ac:	55                   	push   %ebp
f01029ad:	89 e5                	mov    %esp,%ebp
f01029af:	57                   	push   %edi
f01029b0:	56                   	push   %esi
f01029b1:	53                   	push   %ebx
f01029b2:	83 ec 1c             	sub    $0x1c,%esp
f01029b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01029b8:	89 d7                	mov    %edx,%edi
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	
	assert(rcr3()==PADDR(kern_pgdir));
f01029ba:	e8 14 fe ff ff       	call   f01027d3 <rcr3>
f01029bf:	89 c3                	mov    %eax,%ebx
f01029c1:	8b 0d a8 6a 19 f0    	mov    0xf0196aa8,%ecx
f01029c7:	ba 64 01 00 00       	mov    $0x164,%edx
f01029cc:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f01029d1:	e8 60 fe ff ff       	call   f0102836 <_paddr>
f01029d6:	39 c3                	cmp    %eax,%ebx
f01029d8:	74 19                	je     f01029f3 <load_icode+0x47>
f01029da:	68 f8 53 10 f0       	push   $0xf01053f8
f01029df:	68 7a 50 10 f0       	push   $0xf010507a
f01029e4:	68 64 01 00 00       	push   $0x164
f01029e9:	68 c2 53 10 f0       	push   $0xf01053c2
f01029ee:	e8 b6 d6 ff ff       	call   f01000a9 <_panic>
	lcr3(PADDR(e->env_pgdir));//cambio a pgdir del env para que anden memcpy y memset
f01029f3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01029f6:	8b 4e 5c             	mov    0x5c(%esi),%ecx
f01029f9:	ba 65 01 00 00       	mov    $0x165,%edx
f01029fe:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102a03:	e8 2e fe ff ff       	call   f0102836 <_paddr>
f0102a08:	e8 be fd ff ff       	call   f01027cb <lcr3>
	assert(rcr3()==PADDR(e->env_pgdir));
f0102a0d:	e8 c1 fd ff ff       	call   f01027d3 <rcr3>
f0102a12:	89 c3                	mov    %eax,%ebx
f0102a14:	8b 4e 5c             	mov    0x5c(%esi),%ecx
f0102a17:	ba 66 01 00 00       	mov    $0x166,%edx
f0102a1c:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102a21:	e8 10 fe ff ff       	call   f0102836 <_paddr>
f0102a26:	39 c3                	cmp    %eax,%ebx
f0102a28:	74 19                	je     f0102a43 <load_icode+0x97>
f0102a2a:	68 12 54 10 f0       	push   $0xf0105412
f0102a2f:	68 7a 50 10 f0       	push   $0xf010507a
f0102a34:	68 66 01 00 00       	push   $0x166
f0102a39:	68 c2 53 10 f0       	push   $0xf01053c2
f0102a3e:	e8 66 d6 ff ff       	call   f01000a9 <_panic>

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f0102a43:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102a49:	74 17                	je     f0102a62 <load_icode+0xb6>
f0102a4b:	83 ec 04             	sub    $0x4,%esp
f0102a4e:	68 2e 54 10 f0       	push   $0xf010542e
f0102a53:	68 69 01 00 00       	push   $0x169
f0102a58:	68 c2 53 10 f0       	push   $0xf01053c2
f0102a5d:	e8 47 d6 ff ff       	call   f01000a9 <_panic>

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f0102a62:	89 fe                	mov    %edi,%esi
f0102a64:	03 77 1c             	add    0x1c(%edi),%esi
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f0102a67:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a6c:	eb 4c                	jmp    f0102aba <load_icode+0x10e>
		va=(void*) ph->p_va;
		if (ph->p_type != ELF_PROG_LOAD) continue;
f0102a6e:	83 3e 01             	cmpl   $0x1,(%esi)
f0102a71:	75 44                	jne    f0102ab7 <load_icode+0x10b>
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
		va=(void*) ph->p_va;
f0102a73:	8b 46 08             	mov    0x8(%esi),%eax
		if (ph->p_type != ELF_PROG_LOAD) continue;
		region_alloc(e,va,ph->p_memsz);
f0102a76:	8b 4e 14             	mov    0x14(%esi),%ecx
f0102a79:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102a7c:	89 c2                	mov    %eax,%edx
f0102a7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102a81:	e8 6c fe ff ff       	call   f01028f2 <region_alloc>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);
f0102a86:	83 ec 04             	sub    $0x4,%esp
f0102a89:	ff 76 10             	pushl  0x10(%esi)
f0102a8c:	89 f9                	mov    %edi,%ecx
f0102a8e:	03 4e 04             	add    0x4(%esi),%ecx
f0102a91:	51                   	push   %ecx
f0102a92:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a95:	e8 9f 14 00 00       	call   f0103f39 <memcpy>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f0102a9a:	8b 46 10             	mov    0x10(%esi),%eax
f0102a9d:	83 c4 0c             	add    $0xc,%esp
f0102aa0:	8b 56 14             	mov    0x14(%esi),%edx
f0102aa3:	29 c2                	sub    %eax,%edx
f0102aa5:	52                   	push   %edx
f0102aa6:	6a 00                	push   $0x0
f0102aa8:	03 45 e0             	add    -0x20(%ebp),%eax
f0102aab:	50                   	push   %eax
f0102aac:	e8 d2 13 00 00       	call   f0103e83 <memset>
		ph++;
f0102ab1:	83 c6 20             	add    $0x20,%esi
f0102ab4:	83 c4 10             	add    $0x10,%esp
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++){
f0102ab7:	83 c3 01             	add    $0x1,%ebx
f0102aba:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0102abe:	39 c3                	cmp    %eax,%ebx
f0102ac0:	7c ac                	jl     f0102a6e <load_icode+0xc2>
		ph++;
		//ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f0102ac2:	8b 47 18             	mov    0x18(%edi),%eax
f0102ac5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102ac8:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)USTACKTOP - PGSIZE,PGSIZE);
f0102acb:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102ad0:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102ad5:	89 f8                	mov    %edi,%eax
f0102ad7:	e8 16 fe ff ff       	call   f01028f2 <region_alloc>

	lcr3(PADDR(kern_pgdir));//vuelvo a poner el pgdir del kernel 
f0102adc:	8b 0d a8 6a 19 f0    	mov    0xf0196aa8,%ecx
f0102ae2:	ba 81 01 00 00       	mov    $0x181,%edx
f0102ae7:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102aec:	e8 45 fd ff ff       	call   f0102836 <_paddr>
f0102af1:	e8 d5 fc ff ff       	call   f01027cb <lcr3>
}
f0102af6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102af9:	5b                   	pop    %ebx
f0102afa:	5e                   	pop    %esi
f0102afb:	5f                   	pop    %edi
f0102afc:	5d                   	pop    %ebp
f0102afd:	c3                   	ret    

f0102afe <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102afe:	55                   	push   %ebp
f0102aff:	89 e5                	mov    %esp,%ebp
f0102b01:	8b 55 08             	mov    0x8(%ebp),%edx
f0102b04:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102b07:	85 d2                	test   %edx,%edx
f0102b09:	75 11                	jne    f0102b1c <envid2env+0x1e>
		*env_store = curenv;
f0102b0b:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f0102b10:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b13:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102b15:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b1a:	eb 5e                	jmp    f0102b7a <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102b1c:	89 d0                	mov    %edx,%eax
f0102b1e:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102b23:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102b26:	c1 e0 05             	shl    $0x5,%eax
f0102b29:	03 05 e4 4d 19 f0    	add    0xf0194de4,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102b2f:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102b33:	74 05                	je     f0102b3a <envid2env+0x3c>
f0102b35:	3b 50 48             	cmp    0x48(%eax),%edx
f0102b38:	74 10                	je     f0102b4a <envid2env+0x4c>
		*env_store = 0;
f0102b3a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b3d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b43:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b48:	eb 30                	jmp    f0102b7a <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102b4a:	84 c9                	test   %cl,%cl
f0102b4c:	74 22                	je     f0102b70 <envid2env+0x72>
f0102b4e:	8b 15 e0 4d 19 f0    	mov    0xf0194de0,%edx
f0102b54:	39 d0                	cmp    %edx,%eax
f0102b56:	74 18                	je     f0102b70 <envid2env+0x72>
f0102b58:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102b5b:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102b5e:	74 10                	je     f0102b70 <envid2env+0x72>
		*env_store = 0;
f0102b60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b63:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b69:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b6e:	eb 0a                	jmp    f0102b7a <envid2env+0x7c>
	}

	*env_store = e;
f0102b70:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102b73:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102b75:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b7a:	5d                   	pop    %ebp
f0102b7b:	c3                   	ret    

f0102b7c <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102b7c:	55                   	push   %ebp
f0102b7d:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f0102b7f:	b8 00 f3 10 f0       	mov    $0xf010f300,%eax
f0102b84:	e8 32 fc ff ff       	call   f01027bb <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f0102b89:	b8 23 00 00 00       	mov    $0x23,%eax
f0102b8e:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f0102b90:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f0102b92:	b8 10 00 00 00       	mov    $0x10,%eax
f0102b97:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f0102b99:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0102b9b:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0102b9d:	ea a4 2b 10 f0 08 00 	ljmp   $0x8,$0xf0102ba4
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f0102ba4:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ba9:	e8 15 fc ff ff       	call   f01027c3 <lldt>
}
f0102bae:	5d                   	pop    %ebp
f0102baf:	c3                   	ret    

f0102bb0 <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
		envs[i].env_status = ENV_FREE; 
f0102bb0:	8b 15 e4 4d 19 f0    	mov    0xf0194de4,%edx
f0102bb6:	8d 42 60             	lea    0x60(%edx),%eax
f0102bb9:	81 c2 00 80 01 00    	add    $0x18000,%edx
f0102bbf:	c7 40 f4 00 00 00 00 	movl   $0x0,-0xc(%eax)
		envs[i].env_id = 0;
f0102bc6:	c7 40 e8 00 00 00 00 	movl   $0x0,-0x18(%eax)
		envs[i].env_link = &envs[i+1];
f0102bcd:	89 40 e4             	mov    %eax,-0x1c(%eax)
f0102bd0:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
f0102bd3:	39 d0                	cmp    %edx,%eax
f0102bd5:	75 e8                	jne    f0102bbf <env_init+0xf>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102bd7:	55                   	push   %ebp
f0102bd8:	89 e5                	mov    %esp,%ebp
		envs[i].env_status = ENV_FREE; 
		envs[i].env_id = 0;
		envs[i].env_link = &envs[i+1];
		
	}
	envs[NENV-1].env_status = ENV_FREE;
f0102bda:	a1 e4 4d 19 f0       	mov    0xf0194de4,%eax
f0102bdf:	c7 80 f4 7f 01 00 00 	movl   $0x0,0x17ff4(%eax)
f0102be6:	00 00 00 
	envs[NENV-1].env_id = 0;
f0102be9:	c7 80 e8 7f 01 00 00 	movl   $0x0,0x17fe8(%eax)
f0102bf0:	00 00 00 
	env_free_list = &envs[0];
f0102bf3:	a3 e8 4d 19 f0       	mov    %eax,0xf0194de8
	// Per-CPU part of the initialization
	env_init_percpu();
f0102bf8:	e8 7f ff ff ff       	call   f0102b7c <env_init_percpu>
}
f0102bfd:	5d                   	pop    %ebp
f0102bfe:	c3                   	ret    

f0102bff <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102bff:	55                   	push   %ebp
f0102c00:	89 e5                	mov    %esp,%ebp
f0102c02:	53                   	push   %ebx
f0102c03:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102c06:	8b 1d e8 4d 19 f0    	mov    0xf0194de8,%ebx
f0102c0c:	85 db                	test   %ebx,%ebx
f0102c0e:	0f 84 c0 00 00 00    	je     f0102cd4 <env_alloc+0xd5>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f0102c14:	89 d8                	mov    %ebx,%eax
f0102c16:	e8 3d fc ff ff       	call   f0102858 <env_setup_vm>
f0102c1b:	85 c0                	test   %eax,%eax
f0102c1d:	0f 88 b6 00 00 00    	js     f0102cd9 <env_alloc+0xda>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102c23:	8b 43 48             	mov    0x48(%ebx),%eax
f0102c26:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f0102c2b:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102c30:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102c35:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102c38:	89 da                	mov    %ebx,%edx
f0102c3a:	2b 15 e4 4d 19 f0    	sub    0xf0194de4,%edx
f0102c40:	c1 fa 05             	sar    $0x5,%edx
f0102c43:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102c49:	09 d0                	or     %edx,%eax
f0102c4b:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102c4e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c51:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102c54:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102c5b:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102c62:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102c69:	83 ec 04             	sub    $0x4,%esp
f0102c6c:	6a 44                	push   $0x44
f0102c6e:	6a 00                	push   $0x0
f0102c70:	53                   	push   %ebx
f0102c71:	e8 0d 12 00 00       	call   f0103e83 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102c76:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102c7c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102c82:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102c88:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102c8f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102c95:	8b 43 44             	mov    0x44(%ebx),%eax
f0102c98:	a3 e8 4d 19 f0       	mov    %eax,0xf0194de8
	*newenv_store = e; 
f0102c9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ca0:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ca2:	8b 53 48             	mov    0x48(%ebx),%edx
f0102ca5:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f0102caa:	83 c4 10             	add    $0x10,%esp
f0102cad:	85 c0                	test   %eax,%eax
f0102caf:	74 05                	je     f0102cb6 <env_alloc+0xb7>
f0102cb1:	8b 40 48             	mov    0x48(%eax),%eax
f0102cb4:	eb 05                	jmp    f0102cbb <env_alloc+0xbc>
f0102cb6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cbb:	83 ec 04             	sub    $0x4,%esp
f0102cbe:	52                   	push   %edx
f0102cbf:	50                   	push   %eax
f0102cc0:	68 3d 54 10 f0       	push   $0xf010543d
f0102cc5:	e8 05 03 00 00       	call   f0102fcf <cprintf>
	return 0;
f0102cca:	83 c4 10             	add    $0x10,%esp
f0102ccd:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cd2:	eb 05                	jmp    f0102cd9 <env_alloc+0xda>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102cd4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102cd9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102cdc:	c9                   	leave  
f0102cdd:	c3                   	ret    

f0102cde <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102cde:	55                   	push   %ebp
f0102cdf:	89 e5                	mov    %esp,%ebp
f0102ce1:	83 ec 20             	sub    $0x20,%esp
	// LAB 3: Your code here.
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f0102ce4:	6a 00                	push   $0x0
f0102ce6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102ce9:	50                   	push   %eax
f0102cea:	e8 10 ff ff ff       	call   f0102bff <env_alloc>
	if (err<0) panic("env_create: %e", err);
f0102cef:	83 c4 10             	add    $0x10,%esp
f0102cf2:	85 c0                	test   %eax,%eax
f0102cf4:	79 15                	jns    f0102d0b <env_create+0x2d>
f0102cf6:	50                   	push   %eax
f0102cf7:	68 52 54 10 f0       	push   $0xf0105452
f0102cfc:	68 91 01 00 00       	push   $0x191
f0102d01:	68 c2 53 10 f0       	push   $0xf01053c2
f0102d06:	e8 9e d3 ff ff       	call   f01000a9 <_panic>
	load_icode(e,binary);
f0102d0b:	8b 55 08             	mov    0x8(%ebp),%edx
f0102d0e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d11:	e8 96 fc ff ff       	call   f01029ac <load_icode>
	e->env_type = type;
f0102d16:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d19:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102d1c:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102d1f:	c9                   	leave  
f0102d20:	c3                   	ret    

f0102d21 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102d21:	55                   	push   %ebp
f0102d22:	89 e5                	mov    %esp,%ebp
f0102d24:	57                   	push   %edi
f0102d25:	56                   	push   %esi
f0102d26:	53                   	push   %ebx
f0102d27:	83 ec 1c             	sub    $0x1c,%esp
f0102d2a:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102d2d:	39 3d e0 4d 19 f0    	cmp    %edi,0xf0194de0
f0102d33:	75 1a                	jne    f0102d4f <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f0102d35:	8b 0d a8 6a 19 f0    	mov    0xf0196aa8,%ecx
f0102d3b:	ba a4 01 00 00       	mov    $0x1a4,%edx
f0102d40:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102d45:	e8 ec fa ff ff       	call   f0102836 <_paddr>
f0102d4a:	e8 7c fa ff ff       	call   f01027cb <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d4f:	8b 57 48             	mov    0x48(%edi),%edx
f0102d52:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f0102d57:	85 c0                	test   %eax,%eax
f0102d59:	74 05                	je     f0102d60 <env_free+0x3f>
f0102d5b:	8b 40 48             	mov    0x48(%eax),%eax
f0102d5e:	eb 05                	jmp    f0102d65 <env_free+0x44>
f0102d60:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d65:	83 ec 04             	sub    $0x4,%esp
f0102d68:	52                   	push   %edx
f0102d69:	50                   	push   %eax
f0102d6a:	68 61 54 10 f0       	push   $0xf0105461
f0102d6f:	e8 5b 02 00 00       	call   f0102fcf <cprintf>
f0102d74:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102d77:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102d7e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102d81:	89 c8                	mov    %ecx,%eax
f0102d83:	c1 e0 02             	shl    $0x2,%eax
f0102d86:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102d89:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102d8c:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102d8f:	a8 01                	test   $0x1,%al
f0102d91:	74 72                	je     f0102e05 <env_free+0xe4>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102d93:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102d98:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f0102d9b:	89 c1                	mov    %eax,%ecx
f0102d9d:	ba b2 01 00 00       	mov    $0x1b2,%edx
f0102da2:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102da7:	e8 40 fa ff ff       	call   f01027ec <_kaddr>
f0102dac:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102dae:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102db1:	c1 e0 16             	shl    $0x16,%eax
f0102db4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102db7:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102dbc:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f0102dc0:	74 17                	je     f0102dd9 <env_free+0xb8>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102dc2:	83 ec 08             	sub    $0x8,%esp
f0102dc5:	89 d8                	mov    %ebx,%eax
f0102dc7:	c1 e0 0c             	shl    $0xc,%eax
f0102dca:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102dcd:	50                   	push   %eax
f0102dce:	ff 77 5c             	pushl  0x5c(%edi)
f0102dd1:	e8 1c ea ff ff       	call   f01017f2 <page_remove>
f0102dd6:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102dd9:	83 c3 01             	add    $0x1,%ebx
f0102ddc:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102de2:	75 d8                	jne    f0102dbc <env_free+0x9b>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102de4:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102de7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102dea:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f0102df1:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102df4:	e8 cd fa ff ff       	call   f01028c6 <pa2page>
f0102df9:	83 ec 0c             	sub    $0xc,%esp
f0102dfc:	50                   	push   %eax
f0102dfd:	e8 1c e8 ff ff       	call   f010161e <page_decref>
f0102e02:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e05:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102e09:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e0c:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e11:	0f 85 67 ff ff ff    	jne    f0102d7e <env_free+0x5d>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102e17:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f0102e1a:	ba c0 01 00 00       	mov    $0x1c0,%edx
f0102e1f:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102e24:	e8 0d fa ff ff       	call   f0102836 <_paddr>
	e->env_pgdir = 0;
f0102e29:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f0102e30:	e8 91 fa ff ff       	call   f01028c6 <pa2page>
f0102e35:	83 ec 0c             	sub    $0xc,%esp
f0102e38:	50                   	push   %eax
f0102e39:	e8 e0 e7 ff ff       	call   f010161e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102e3e:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102e45:	a1 e8 4d 19 f0       	mov    0xf0194de8,%eax
f0102e4a:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102e4d:	89 3d e8 4d 19 f0    	mov    %edi,0xf0194de8
}
f0102e53:	83 c4 10             	add    $0x10,%esp
f0102e56:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e59:	5b                   	pop    %ebx
f0102e5a:	5e                   	pop    %esi
f0102e5b:	5f                   	pop    %edi
f0102e5c:	5d                   	pop    %ebp
f0102e5d:	c3                   	ret    

f0102e5e <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102e5e:	55                   	push   %ebp
f0102e5f:	89 e5                	mov    %esp,%ebp
f0102e61:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102e64:	ff 75 08             	pushl  0x8(%ebp)
f0102e67:	e8 b5 fe ff ff       	call   f0102d21 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102e6c:	c7 04 24 8c 53 10 f0 	movl   $0xf010538c,(%esp)
f0102e73:	e8 57 01 00 00       	call   f0102fcf <cprintf>
f0102e78:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102e7b:	83 ec 0c             	sub    $0xc,%esp
f0102e7e:	6a 00                	push   $0x0
f0102e80:	e8 41 db ff ff       	call   f01009c6 <monitor>
f0102e85:	83 c4 10             	add    $0x10,%esp
f0102e88:	eb f1                	jmp    f0102e7b <env_destroy+0x1d>

f0102e8a <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102e8a:	55                   	push   %ebp
f0102e8b:	89 e5                	mov    %esp,%ebp
f0102e8d:	83 ec 0c             	sub    $0xc,%esp
	asm volatile("\tmovl %0,%%esp\n"
f0102e90:	8b 65 08             	mov    0x8(%ebp),%esp
f0102e93:	61                   	popa   
f0102e94:	07                   	pop    %es
f0102e95:	1f                   	pop    %ds
f0102e96:	83 c4 08             	add    $0x8,%esp
f0102e99:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f0102e9a:	68 77 54 10 f0       	push   $0xf0105477
f0102e9f:	68 ea 01 00 00       	push   $0x1ea
f0102ea4:	68 c2 53 10 f0       	push   $0xf01053c2
f0102ea9:	e8 fb d1 ff ff       	call   f01000a9 <_panic>

f0102eae <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102eae:	55                   	push   %ebp
f0102eaf:	89 e5                	mov    %esp,%ebp
f0102eb1:	83 ec 08             	sub    $0x8,%esp
f0102eb4:	8b 55 08             	mov    0x8(%ebp),%edx

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f0102eb7:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f0102ebc:	85 c0                	test   %eax,%eax
f0102ebe:	74 0d                	je     f0102ecd <env_run+0x1f>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f0102ec0:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102ec4:	75 07                	jne    f0102ecd <env_run+0x1f>
f0102ec6:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si FREE no tiene nada, no tiene sentido
		//si DYING ????
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	assert(e->env_status != ENV_FREE);//DEBUG2
f0102ecd:	8b 42 54             	mov    0x54(%edx),%eax
f0102ed0:	85 c0                	test   %eax,%eax
f0102ed2:	75 19                	jne    f0102eed <env_run+0x3f>
f0102ed4:	68 83 54 10 f0       	push   $0xf0105483
f0102ed9:	68 7a 50 10 f0       	push   $0xf010507a
f0102ede:	68 13 02 00 00       	push   $0x213
f0102ee3:	68 c2 53 10 f0       	push   $0xf01053c2
f0102ee8:	e8 bc d1 ff ff       	call   f01000a9 <_panic>
	assert(e->env_status == ENV_RUNNABLE);//DEBUG2
f0102eed:	83 f8 02             	cmp    $0x2,%eax
f0102ef0:	74 19                	je     f0102f0b <env_run+0x5d>
f0102ef2:	68 9d 54 10 f0       	push   $0xf010549d
f0102ef7:	68 7a 50 10 f0       	push   $0xf010507a
f0102efc:	68 14 02 00 00       	push   $0x214
f0102f01:	68 c2 53 10 f0       	push   $0xf01053c2
f0102f06:	e8 9e d1 ff ff       	call   f01000a9 <_panic>
	curenv=e;
f0102f0b:	89 15 e0 4d 19 f0    	mov    %edx,0xf0194de0
	curenv->env_status = ENV_RUNNING;
f0102f11:	c7 42 54 03 00 00 00 	movl   $0x3,0x54(%edx)
	curenv->env_runs++;
f0102f18:	83 42 58 01          	addl   $0x1,0x58(%edx)
	lcr3(PADDR(curenv->env_pgdir));
f0102f1c:	8b 4a 5c             	mov    0x5c(%edx),%ecx
f0102f1f:	ba 18 02 00 00       	mov    $0x218,%edx
f0102f24:	b8 c2 53 10 f0       	mov    $0xf01053c2,%eax
f0102f29:	e8 08 f9 ff ff       	call   f0102836 <_paddr>
f0102f2e:	e8 98 f8 ff ff       	call   f01027cb <lcr3>
	env_pop_tf(&(curenv->env_tf));
f0102f33:	83 ec 0c             	sub    $0xc,%esp
f0102f36:	ff 35 e0 4d 19 f0    	pushl  0xf0194de0
f0102f3c:	e8 49 ff ff ff       	call   f0102e8a <env_pop_tf>

f0102f41 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0102f41:	55                   	push   %ebp
f0102f42:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f44:	89 c2                	mov    %eax,%edx
f0102f46:	ec                   	in     (%dx),%al
	return data;
}
f0102f47:	5d                   	pop    %ebp
f0102f48:	c3                   	ret    

f0102f49 <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102f49:	55                   	push   %ebp
f0102f4a:	89 e5                	mov    %esp,%ebp
f0102f4c:	89 c1                	mov    %eax,%ecx
f0102f4e:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f50:	89 ca                	mov    %ecx,%edx
f0102f52:	ee                   	out    %al,(%dx)
}
f0102f53:	5d                   	pop    %ebp
f0102f54:	c3                   	ret    

f0102f55 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f55:	55                   	push   %ebp
f0102f56:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102f58:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102f5c:	b8 70 00 00 00       	mov    $0x70,%eax
f0102f61:	e8 e3 ff ff ff       	call   f0102f49 <outb>
	return inb(IO_RTC+1);
f0102f66:	b8 71 00 00 00       	mov    $0x71,%eax
f0102f6b:	e8 d1 ff ff ff       	call   f0102f41 <inb>
f0102f70:	0f b6 c0             	movzbl %al,%eax
}
f0102f73:	5d                   	pop    %ebp
f0102f74:	c3                   	ret    

f0102f75 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f75:	55                   	push   %ebp
f0102f76:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f0102f78:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f0102f7c:	b8 70 00 00 00       	mov    $0x70,%eax
f0102f81:	e8 c3 ff ff ff       	call   f0102f49 <outb>
	outb(IO_RTC+1, datum);
f0102f86:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f0102f8a:	b8 71 00 00 00       	mov    $0x71,%eax
f0102f8f:	e8 b5 ff ff ff       	call   f0102f49 <outb>
}
f0102f94:	5d                   	pop    %ebp
f0102f95:	c3                   	ret    

f0102f96 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f96:	55                   	push   %ebp
f0102f97:	89 e5                	mov    %esp,%ebp
f0102f99:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0102f9c:	ff 75 08             	pushl  0x8(%ebp)
f0102f9f:	e8 7f d7 ff ff       	call   f0100723 <cputchar>
	*cnt++;
}
f0102fa4:	83 c4 10             	add    $0x10,%esp
f0102fa7:	c9                   	leave  
f0102fa8:	c3                   	ret    

f0102fa9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102fa9:	55                   	push   %ebp
f0102faa:	89 e5                	mov    %esp,%ebp
f0102fac:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0102faf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102fb6:	ff 75 0c             	pushl  0xc(%ebp)
f0102fb9:	ff 75 08             	pushl  0x8(%ebp)
f0102fbc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102fbf:	50                   	push   %eax
f0102fc0:	68 96 2f 10 f0       	push   $0xf0102f96
f0102fc5:	e8 92 08 00 00       	call   f010385c <vprintfmt>
	return cnt;
}
f0102fca:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102fcd:	c9                   	leave  
f0102fce:	c3                   	ret    

f0102fcf <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102fcf:	55                   	push   %ebp
f0102fd0:	89 e5                	mov    %esp,%ebp
f0102fd2:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102fd5:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102fd8:	50                   	push   %eax
f0102fd9:	ff 75 08             	pushl  0x8(%ebp)
f0102fdc:	e8 c8 ff ff ff       	call   f0102fa9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102fe1:	c9                   	leave  
f0102fe2:	c3                   	ret    

f0102fe3 <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f0102fe3:	55                   	push   %ebp
f0102fe4:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f0102fe6:	0f 01 18             	lidtl  (%eax)
}
f0102fe9:	5d                   	pop    %ebp
f0102fea:	c3                   	ret    

f0102feb <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f0102feb:	55                   	push   %ebp
f0102fec:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f0102fee:	0f 00 d8             	ltr    %ax
}
f0102ff1:	5d                   	pop    %ebp
f0102ff2:	c3                   	ret    

f0102ff3 <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f0102ff3:	55                   	push   %ebp
f0102ff4:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0102ff6:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f0102ff9:	5d                   	pop    %ebp
f0102ffa:	c3                   	ret    

f0102ffb <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f0102ffb:	55                   	push   %ebp
f0102ffc:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0102ffe:	9c                   	pushf  
f0102fff:	58                   	pop    %eax
	return eflags;
}
f0103000:	5d                   	pop    %ebp
f0103001:	c3                   	ret    

f0103002 <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f0103002:	55                   	push   %ebp
f0103003:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f0103005:	83 f8 13             	cmp    $0x13,%eax
f0103008:	77 09                	ja     f0103013 <trapname+0x11>
		return excnames[trapno];
f010300a:	8b 04 85 20 58 10 f0 	mov    -0xfefa7e0(,%eax,4),%eax
f0103011:	eb 10                	jmp    f0103023 <trapname+0x21>
	if (trapno == T_SYSCALL)
f0103013:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
	return "(unknown trap)";
f0103016:	ba c7 54 10 f0       	mov    $0xf01054c7,%edx
f010301b:	b8 bb 54 10 f0       	mov    $0xf01054bb,%eax
f0103020:	0f 45 c2             	cmovne %edx,%eax
}
f0103023:	5d                   	pop    %ebp
f0103024:	c3                   	ret    

f0103025 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103025:	55                   	push   %ebp
f0103026:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103028:	b8 20 56 19 f0       	mov    $0xf0195620,%eax
f010302d:	c7 05 24 56 19 f0 00 	movl   $0xf0000000,0xf0195624
f0103034:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103037:	66 c7 05 28 56 19 f0 	movw   $0x10,0xf0195628
f010303e:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f0103040:	66 c7 05 48 f3 10 f0 	movw   $0x67,0xf010f348
f0103047:	67 00 
f0103049:	66 a3 4a f3 10 f0    	mov    %ax,0xf010f34a
f010304f:	89 c2                	mov    %eax,%edx
f0103051:	c1 ea 10             	shr    $0x10,%edx
f0103054:	88 15 4c f3 10 f0    	mov    %dl,0xf010f34c
f010305a:	c6 05 4e f3 10 f0 40 	movb   $0x40,0xf010f34e
f0103061:	c1 e8 18             	shr    $0x18,%eax
f0103064:	a2 4f f3 10 f0       	mov    %al,0xf010f34f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103069:	c6 05 4d f3 10 f0 89 	movb   $0x89,0xf010f34d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f0103070:	b8 28 00 00 00       	mov    $0x28,%eax
f0103075:	e8 71 ff ff ff       	call   f0102feb <ltr>

	// Load the IDT
	lidt(&idt_pd);
f010307a:	b8 50 f3 10 f0       	mov    $0xf010f350,%eax
f010307f:	e8 5f ff ff ff       	call   f0102fe3 <lidt>
}
f0103084:	5d                   	pop    %ebp
f0103085:	c3                   	ret    

f0103086 <trap_init>:
}


void
trap_init(void)
{
f0103086:	55                   	push   %ebp
f0103087:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup
	trap_init_percpu();
f0103089:	e8 97 ff ff ff       	call   f0103025 <trap_init_percpu>
}
f010308e:	5d                   	pop    %ebp
f010308f:	c3                   	ret    

f0103090 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103090:	55                   	push   %ebp
f0103091:	89 e5                	mov    %esp,%ebp
f0103093:	53                   	push   %ebx
f0103094:	83 ec 0c             	sub    $0xc,%esp
f0103097:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010309a:	ff 33                	pushl  (%ebx)
f010309c:	68 d6 54 10 f0       	push   $0xf01054d6
f01030a1:	e8 29 ff ff ff       	call   f0102fcf <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01030a6:	83 c4 08             	add    $0x8,%esp
f01030a9:	ff 73 04             	pushl  0x4(%ebx)
f01030ac:	68 e5 54 10 f0       	push   $0xf01054e5
f01030b1:	e8 19 ff ff ff       	call   f0102fcf <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01030b6:	83 c4 08             	add    $0x8,%esp
f01030b9:	ff 73 08             	pushl  0x8(%ebx)
f01030bc:	68 f4 54 10 f0       	push   $0xf01054f4
f01030c1:	e8 09 ff ff ff       	call   f0102fcf <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01030c6:	83 c4 08             	add    $0x8,%esp
f01030c9:	ff 73 0c             	pushl  0xc(%ebx)
f01030cc:	68 03 55 10 f0       	push   $0xf0105503
f01030d1:	e8 f9 fe ff ff       	call   f0102fcf <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01030d6:	83 c4 08             	add    $0x8,%esp
f01030d9:	ff 73 10             	pushl  0x10(%ebx)
f01030dc:	68 12 55 10 f0       	push   $0xf0105512
f01030e1:	e8 e9 fe ff ff       	call   f0102fcf <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01030e6:	83 c4 08             	add    $0x8,%esp
f01030e9:	ff 73 14             	pushl  0x14(%ebx)
f01030ec:	68 21 55 10 f0       	push   $0xf0105521
f01030f1:	e8 d9 fe ff ff       	call   f0102fcf <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01030f6:	83 c4 08             	add    $0x8,%esp
f01030f9:	ff 73 18             	pushl  0x18(%ebx)
f01030fc:	68 30 55 10 f0       	push   $0xf0105530
f0103101:	e8 c9 fe ff ff       	call   f0102fcf <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103106:	83 c4 08             	add    $0x8,%esp
f0103109:	ff 73 1c             	pushl  0x1c(%ebx)
f010310c:	68 3f 55 10 f0       	push   $0xf010553f
f0103111:	e8 b9 fe ff ff       	call   f0102fcf <cprintf>
}
f0103116:	83 c4 10             	add    $0x10,%esp
f0103119:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010311c:	c9                   	leave  
f010311d:	c3                   	ret    

f010311e <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010311e:	55                   	push   %ebp
f010311f:	89 e5                	mov    %esp,%ebp
f0103121:	56                   	push   %esi
f0103122:	53                   	push   %ebx
f0103123:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103126:	83 ec 08             	sub    $0x8,%esp
f0103129:	53                   	push   %ebx
f010312a:	68 73 56 10 f0       	push   $0xf0105673
f010312f:	e8 9b fe ff ff       	call   f0102fcf <cprintf>
	print_regs(&tf->tf_regs);
f0103134:	89 1c 24             	mov    %ebx,(%esp)
f0103137:	e8 54 ff ff ff       	call   f0103090 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010313c:	83 c4 08             	add    $0x8,%esp
f010313f:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103143:	50                   	push   %eax
f0103144:	68 75 55 10 f0       	push   $0xf0105575
f0103149:	e8 81 fe ff ff       	call   f0102fcf <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010314e:	83 c4 08             	add    $0x8,%esp
f0103151:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103155:	50                   	push   %eax
f0103156:	68 88 55 10 f0       	push   $0xf0105588
f010315b:	e8 6f fe ff ff       	call   f0102fcf <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103160:	8b 73 28             	mov    0x28(%ebx),%esi
f0103163:	89 f0                	mov    %esi,%eax
f0103165:	e8 98 fe ff ff       	call   f0103002 <trapname>
f010316a:	83 c4 0c             	add    $0xc,%esp
f010316d:	50                   	push   %eax
f010316e:	56                   	push   %esi
f010316f:	68 9b 55 10 f0       	push   $0xf010559b
f0103174:	e8 56 fe ff ff       	call   f0102fcf <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103179:	83 c4 10             	add    $0x10,%esp
f010317c:	3b 1d 00 56 19 f0    	cmp    0xf0195600,%ebx
f0103182:	75 1c                	jne    f01031a0 <print_trapframe+0x82>
f0103184:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103188:	75 16                	jne    f01031a0 <print_trapframe+0x82>
		cprintf("  cr2  0x%08x\n", rcr2());
f010318a:	e8 64 fe ff ff       	call   f0102ff3 <rcr2>
f010318f:	83 ec 08             	sub    $0x8,%esp
f0103192:	50                   	push   %eax
f0103193:	68 ad 55 10 f0       	push   $0xf01055ad
f0103198:	e8 32 fe ff ff       	call   f0102fcf <cprintf>
f010319d:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01031a0:	83 ec 08             	sub    $0x8,%esp
f01031a3:	ff 73 2c             	pushl  0x2c(%ebx)
f01031a6:	68 bc 55 10 f0       	push   $0xf01055bc
f01031ab:	e8 1f fe ff ff       	call   f0102fcf <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01031b0:	83 c4 10             	add    $0x10,%esp
f01031b3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01031b7:	75 49                	jne    f0103202 <print_trapframe+0xe4>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f01031b9:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01031bc:	89 c2                	mov    %eax,%edx
f01031be:	83 e2 01             	and    $0x1,%edx
f01031c1:	ba 59 55 10 f0       	mov    $0xf0105559,%edx
f01031c6:	b9 4e 55 10 f0       	mov    $0xf010554e,%ecx
f01031cb:	0f 44 ca             	cmove  %edx,%ecx
f01031ce:	89 c2                	mov    %eax,%edx
f01031d0:	83 e2 02             	and    $0x2,%edx
f01031d3:	ba 6b 55 10 f0       	mov    $0xf010556b,%edx
f01031d8:	be 65 55 10 f0       	mov    $0xf0105565,%esi
f01031dd:	0f 45 d6             	cmovne %esi,%edx
f01031e0:	83 e0 04             	and    $0x4,%eax
f01031e3:	be 3e 56 10 f0       	mov    $0xf010563e,%esi
f01031e8:	b8 70 55 10 f0       	mov    $0xf0105570,%eax
f01031ed:	0f 44 c6             	cmove  %esi,%eax
f01031f0:	51                   	push   %ecx
f01031f1:	52                   	push   %edx
f01031f2:	50                   	push   %eax
f01031f3:	68 ca 55 10 f0       	push   $0xf01055ca
f01031f8:	e8 d2 fd ff ff       	call   f0102fcf <cprintf>
f01031fd:	83 c4 10             	add    $0x10,%esp
f0103200:	eb 10                	jmp    f0103212 <print_trapframe+0xf4>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103202:	83 ec 0c             	sub    $0xc,%esp
f0103205:	68 8a 53 10 f0       	push   $0xf010538a
f010320a:	e8 c0 fd ff ff       	call   f0102fcf <cprintf>
f010320f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103212:	83 ec 08             	sub    $0x8,%esp
f0103215:	ff 73 30             	pushl  0x30(%ebx)
f0103218:	68 d9 55 10 f0       	push   $0xf01055d9
f010321d:	e8 ad fd ff ff       	call   f0102fcf <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103222:	83 c4 08             	add    $0x8,%esp
f0103225:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103229:	50                   	push   %eax
f010322a:	68 e8 55 10 f0       	push   $0xf01055e8
f010322f:	e8 9b fd ff ff       	call   f0102fcf <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103234:	83 c4 08             	add    $0x8,%esp
f0103237:	ff 73 38             	pushl  0x38(%ebx)
f010323a:	68 fb 55 10 f0       	push   $0xf01055fb
f010323f:	e8 8b fd ff ff       	call   f0102fcf <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103244:	83 c4 10             	add    $0x10,%esp
f0103247:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010324b:	74 25                	je     f0103272 <print_trapframe+0x154>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010324d:	83 ec 08             	sub    $0x8,%esp
f0103250:	ff 73 3c             	pushl  0x3c(%ebx)
f0103253:	68 0a 56 10 f0       	push   $0xf010560a
f0103258:	e8 72 fd ff ff       	call   f0102fcf <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010325d:	83 c4 08             	add    $0x8,%esp
f0103260:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103264:	50                   	push   %eax
f0103265:	68 19 56 10 f0       	push   $0xf0105619
f010326a:	e8 60 fd ff ff       	call   f0102fcf <cprintf>
f010326f:	83 c4 10             	add    $0x10,%esp
	}
}
f0103272:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103275:	5b                   	pop    %ebx
f0103276:	5e                   	pop    %esi
f0103277:	5d                   	pop    %ebp
f0103278:	c3                   	ret    

f0103279 <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f0103279:	55                   	push   %ebp
f010327a:	89 e5                	mov    %esp,%ebp
f010327c:	53                   	push   %ebx
f010327d:	83 ec 10             	sub    $0x10,%esp
f0103280:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103282:	50                   	push   %eax
f0103283:	e8 96 fe ff ff       	call   f010311e <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103288:	83 c4 10             	add    $0x10,%esp
f010328b:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103290:	75 17                	jne    f01032a9 <trap_dispatch+0x30>
		panic("unhandled trap in kernel");
f0103292:	83 ec 04             	sub    $0x4,%esp
f0103295:	68 2c 56 10 f0       	push   $0xf010562c
f010329a:	68 95 00 00 00       	push   $0x95
f010329f:	68 45 56 10 f0       	push   $0xf0105645
f01032a4:	e8 00 ce ff ff       	call   f01000a9 <_panic>
	else {
		env_destroy(curenv);
f01032a9:	83 ec 0c             	sub    $0xc,%esp
f01032ac:	ff 35 e0 4d 19 f0    	pushl  0xf0194de0
f01032b2:	e8 a7 fb ff ff       	call   f0102e5e <env_destroy>
		return;
f01032b7:	83 c4 10             	add    $0x10,%esp
	}
}
f01032ba:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01032bd:	c9                   	leave  
f01032be:	c3                   	ret    

f01032bf <trap>:

void
trap(struct Trapframe *tf)
{
f01032bf:	55                   	push   %ebp
f01032c0:	89 e5                	mov    %esp,%ebp
f01032c2:	57                   	push   %edi
f01032c3:	56                   	push   %esi
f01032c4:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01032c7:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01032c8:	e8 2e fd ff ff       	call   f0102ffb <read_eflags>
f01032cd:	f6 c4 02             	test   $0x2,%ah
f01032d0:	74 19                	je     f01032eb <trap+0x2c>
f01032d2:	68 51 56 10 f0       	push   $0xf0105651
f01032d7:	68 7a 50 10 f0       	push   $0xf010507a
f01032dc:	68 a6 00 00 00       	push   $0xa6
f01032e1:	68 45 56 10 f0       	push   $0xf0105645
f01032e6:	e8 be cd ff ff       	call   f01000a9 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01032eb:	83 ec 08             	sub    $0x8,%esp
f01032ee:	56                   	push   %esi
f01032ef:	68 6a 56 10 f0       	push   $0xf010566a
f01032f4:	e8 d6 fc ff ff       	call   f0102fcf <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01032f9:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01032fd:	83 e0 03             	and    $0x3,%eax
f0103300:	83 c4 10             	add    $0x10,%esp
f0103303:	66 83 f8 03          	cmp    $0x3,%ax
f0103307:	75 31                	jne    f010333a <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f0103309:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f010330e:	85 c0                	test   %eax,%eax
f0103310:	75 19                	jne    f010332b <trap+0x6c>
f0103312:	68 85 56 10 f0       	push   $0xf0105685
f0103317:	68 7a 50 10 f0       	push   $0xf010507a
f010331c:	68 ac 00 00 00       	push   $0xac
f0103321:	68 45 56 10 f0       	push   $0xf0105645
f0103326:	e8 7e cd ff ff       	call   f01000a9 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010332b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103330:	89 c7                	mov    %eax,%edi
f0103332:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103334:	8b 35 e0 4d 19 f0    	mov    0xf0194de0,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010333a:	89 35 00 56 19 f0    	mov    %esi,0xf0195600

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f0103340:	89 f0                	mov    %esi,%eax
f0103342:	e8 32 ff ff ff       	call   f0103279 <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103347:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f010334c:	85 c0                	test   %eax,%eax
f010334e:	74 06                	je     f0103356 <trap+0x97>
f0103350:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103354:	74 19                	je     f010336f <trap+0xb0>
f0103356:	68 d0 57 10 f0       	push   $0xf01057d0
f010335b:	68 7a 50 10 f0       	push   $0xf010507a
f0103360:	68 be 00 00 00       	push   $0xbe
f0103365:	68 45 56 10 f0       	push   $0xf0105645
f010336a:	e8 3a cd ff ff       	call   f01000a9 <_panic>
	env_run(curenv);
f010336f:	83 ec 0c             	sub    $0xc,%esp
f0103372:	50                   	push   %eax
f0103373:	e8 36 fb ff ff       	call   f0102eae <env_run>

f0103378 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103378:	55                   	push   %ebp
f0103379:	89 e5                	mov    %esp,%ebp
f010337b:	53                   	push   %ebx
f010337c:	83 ec 04             	sub    $0x4,%esp
f010337f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103382:	e8 6c fc ff ff       	call   f0102ff3 <rcr2>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103387:	ff 73 30             	pushl  0x30(%ebx)
f010338a:	50                   	push   %eax
f010338b:	a1 e0 4d 19 f0       	mov    0xf0194de0,%eax
f0103390:	ff 70 48             	pushl  0x48(%eax)
f0103393:	68 fc 57 10 f0       	push   $0xf01057fc
f0103398:	e8 32 fc ff ff       	call   f0102fcf <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f010339d:	89 1c 24             	mov    %ebx,(%esp)
f01033a0:	e8 79 fd ff ff       	call   f010311e <print_trapframe>
	env_destroy(curenv);
f01033a5:	83 c4 04             	add    $0x4,%esp
f01033a8:	ff 35 e0 4d 19 f0    	pushl  0xf0194de0
f01033ae:	e8 ab fa ff ff       	call   f0102e5e <env_destroy>
}
f01033b3:	83 c4 10             	add    $0x10,%esp
f01033b6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01033b9:	c9                   	leave  
f01033ba:	c3                   	ret    

f01033bb <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01033bb:	55                   	push   %ebp
f01033bc:	89 e5                	mov    %esp,%ebp
f01033be:	83 ec 0c             	sub    $0xc,%esp
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	panic("syscall not implemented");
f01033c1:	68 70 58 10 f0       	push   $0xf0105870
f01033c6:	6a 49                	push   $0x49
f01033c8:	68 88 58 10 f0       	push   $0xf0105888
f01033cd:	e8 d7 cc ff ff       	call   f01000a9 <_panic>

f01033d2 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f01033d2:	55                   	push   %ebp
f01033d3:	89 e5                	mov    %esp,%ebp
f01033d5:	57                   	push   %edi
f01033d6:	56                   	push   %esi
f01033d7:	53                   	push   %ebx
f01033d8:	83 ec 14             	sub    $0x14,%esp
f01033db:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01033de:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01033e1:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01033e4:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01033e7:	8b 1a                	mov    (%edx),%ebx
f01033e9:	8b 01                	mov    (%ecx),%eax
f01033eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01033ee:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01033f5:	eb 7f                	jmp    f0103476 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01033f7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01033fa:	01 d8                	add    %ebx,%eax
f01033fc:	89 c6                	mov    %eax,%esi
f01033fe:	c1 ee 1f             	shr    $0x1f,%esi
f0103401:	01 c6                	add    %eax,%esi
f0103403:	d1 fe                	sar    %esi
f0103405:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103408:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010340b:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010340e:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103410:	eb 03                	jmp    f0103415 <stab_binsearch+0x43>
			m--;
f0103412:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103415:	39 c3                	cmp    %eax,%ebx
f0103417:	7f 0d                	jg     f0103426 <stab_binsearch+0x54>
f0103419:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010341d:	83 ea 0c             	sub    $0xc,%edx
f0103420:	39 f9                	cmp    %edi,%ecx
f0103422:	75 ee                	jne    f0103412 <stab_binsearch+0x40>
f0103424:	eb 05                	jmp    f010342b <stab_binsearch+0x59>
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0103426:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103429:	eb 4b                	jmp    f0103476 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010342b:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010342e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103431:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103435:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103438:	76 11                	jbe    f010344b <stab_binsearch+0x79>
			*region_left = m;
f010343a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010343d:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010343f:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103442:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103449:	eb 2b                	jmp    f0103476 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010344b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010344e:	73 14                	jae    f0103464 <stab_binsearch+0x92>
			*region_right = m - 1;
f0103450:	83 e8 01             	sub    $0x1,%eax
f0103453:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103456:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103459:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010345b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103462:	eb 12                	jmp    f0103476 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103464:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103467:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103469:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010346d:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010346f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103476:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103479:	0f 8e 78 ff ff ff    	jle    f01033f7 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010347f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103483:	75 0f                	jne    f0103494 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103485:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103488:	8b 00                	mov    (%eax),%eax
f010348a:	83 e8 01             	sub    $0x1,%eax
f010348d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103490:	89 06                	mov    %eax,(%esi)
f0103492:	eb 2c                	jmp    f01034c0 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103494:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103497:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103499:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010349c:	8b 0e                	mov    (%esi),%ecx
f010349e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01034a1:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01034a4:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01034a7:	eb 03                	jmp    f01034ac <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01034a9:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01034ac:	39 c8                	cmp    %ecx,%eax
f01034ae:	7e 0b                	jle    f01034bb <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01034b0:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01034b4:	83 ea 0c             	sub    $0xc,%edx
f01034b7:	39 df                	cmp    %ebx,%edi
f01034b9:	75 ee                	jne    f01034a9 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f01034bb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01034be:	89 06                	mov    %eax,(%esi)
	}
}
f01034c0:	83 c4 14             	add    $0x14,%esp
f01034c3:	5b                   	pop    %ebx
f01034c4:	5e                   	pop    %esi
f01034c5:	5f                   	pop    %edi
f01034c6:	5d                   	pop    %ebp
f01034c7:	c3                   	ret    

f01034c8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01034c8:	55                   	push   %ebp
f01034c9:	89 e5                	mov    %esp,%ebp
f01034cb:	57                   	push   %edi
f01034cc:	56                   	push   %esi
f01034cd:	53                   	push   %ebx
f01034ce:	83 ec 3c             	sub    $0x3c,%esp
f01034d1:	8b 75 08             	mov    0x8(%ebp),%esi
f01034d4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01034d7:	c7 03 97 58 10 f0    	movl   $0xf0105897,(%ebx)
	info->eip_line = 0;
f01034dd:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01034e4:	c7 43 08 97 58 10 f0 	movl   $0xf0105897,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01034eb:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01034f2:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01034f5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01034fc:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103502:	77 21                	ja     f0103525 <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103504:	a1 00 00 20 00       	mov    0x200000,%eax
f0103509:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f010350c:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103511:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103517:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f010351a:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103520:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103523:	eb 1a                	jmp    f010353f <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103525:	c7 45 bc b1 5a 10 f0 	movl   $0xf0105ab1,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010352c:	c7 45 b8 b1 5a 10 f0 	movl   $0xf0105ab1,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103533:	b8 b0 5a 10 f0       	mov    $0xf0105ab0,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103538:	c7 45 c0 b0 5a 10 f0 	movl   $0xf0105ab0,-0x40(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010353f:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103542:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103545:	0f 83 9a 01 00 00    	jae    f01036e5 <debuginfo_eip+0x21d>
f010354b:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f010354f:	0f 85 97 01 00 00    	jne    f01036ec <debuginfo_eip+0x224>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103555:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010355c:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010355f:	29 f8                	sub    %edi,%eax
f0103561:	c1 f8 02             	sar    $0x2,%eax
f0103564:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010356a:	83 e8 01             	sub    $0x1,%eax
f010356d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103570:	56                   	push   %esi
f0103571:	6a 64                	push   $0x64
f0103573:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103576:	89 c1                	mov    %eax,%ecx
f0103578:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010357b:	89 f8                	mov    %edi,%eax
f010357d:	e8 50 fe ff ff       	call   f01033d2 <stab_binsearch>
	if (lfile == 0)
f0103582:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103585:	83 c4 08             	add    $0x8,%esp
f0103588:	85 c0                	test   %eax,%eax
f010358a:	0f 84 63 01 00 00    	je     f01036f3 <debuginfo_eip+0x22b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103590:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103593:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103596:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103599:	56                   	push   %esi
f010359a:	6a 24                	push   $0x24
f010359c:	8d 45 d8             	lea    -0x28(%ebp),%eax
f010359f:	89 c1                	mov    %eax,%ecx
f01035a1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01035a4:	89 f8                	mov    %edi,%eax
f01035a6:	e8 27 fe ff ff       	call   f01033d2 <stab_binsearch>

	if (lfun <= rfun) {
f01035ab:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035ae:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01035b1:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f01035b4:	83 c4 08             	add    $0x8,%esp
f01035b7:	39 d0                	cmp    %edx,%eax
f01035b9:	7f 2b                	jg     f01035e6 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01035bb:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01035be:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f01035c1:	8b 11                	mov    (%ecx),%edx
f01035c3:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01035c6:	2b 7d b8             	sub    -0x48(%ebp),%edi
f01035c9:	39 fa                	cmp    %edi,%edx
f01035cb:	73 06                	jae    f01035d3 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01035cd:	03 55 b8             	add    -0x48(%ebp),%edx
f01035d0:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01035d3:	8b 51 08             	mov    0x8(%ecx),%edx
f01035d6:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01035d9:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01035db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01035de:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01035e1:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01035e4:	eb 0f                	jmp    f01035f5 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01035e6:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01035e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035ec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01035ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035f2:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01035f5:	83 ec 08             	sub    $0x8,%esp
f01035f8:	6a 3a                	push   $0x3a
f01035fa:	ff 73 08             	pushl  0x8(%ebx)
f01035fd:	e8 65 08 00 00       	call   f0103e67 <strfind>
f0103602:	2b 43 08             	sub    0x8(%ebx),%eax
f0103605:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103608:	83 c4 08             	add    $0x8,%esp
f010360b:	56                   	push   %esi
f010360c:	6a 44                	push   $0x44
f010360e:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103611:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103614:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103617:	89 f0                	mov    %esi,%eax
f0103619:	e8 b4 fd ff ff       	call   f01033d2 <stab_binsearch>
	if (lline <= rline) {
f010361e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103621:	83 c4 10             	add    $0x10,%esp
f0103624:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103627:	7f 0b                	jg     f0103634 <debuginfo_eip+0x16c>
		info->eip_line = stabs[lline].n_desc;
f0103629:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010362c:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103631:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0103634:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103637:	89 d0                	mov    %edx,%eax
f0103639:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010363c:	8b 75 c0             	mov    -0x40(%ebp),%esi
f010363f:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103642:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103646:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103649:	eb 0a                	jmp    f0103655 <debuginfo_eip+0x18d>
f010364b:	83 e8 01             	sub    $0x1,%eax
f010364e:	83 ea 0c             	sub    $0xc,%edx
f0103651:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103655:	39 c7                	cmp    %eax,%edi
f0103657:	7e 05                	jle    f010365e <debuginfo_eip+0x196>
f0103659:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010365c:	eb 47                	jmp    f01036a5 <debuginfo_eip+0x1dd>
f010365e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103662:	80 f9 84             	cmp    $0x84,%cl
f0103665:	75 0e                	jne    f0103675 <debuginfo_eip+0x1ad>
f0103667:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010366a:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f010366e:	74 1c                	je     f010368c <debuginfo_eip+0x1c4>
f0103670:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103673:	eb 17                	jmp    f010368c <debuginfo_eip+0x1c4>
f0103675:	80 f9 64             	cmp    $0x64,%cl
f0103678:	75 d1                	jne    f010364b <debuginfo_eip+0x183>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010367a:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010367e:	74 cb                	je     f010364b <debuginfo_eip+0x183>
f0103680:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103683:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103687:	74 03                	je     f010368c <debuginfo_eip+0x1c4>
f0103689:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010368c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010368f:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103692:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0103695:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103698:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010369b:	29 f8                	sub    %edi,%eax
f010369d:	39 c2                	cmp    %eax,%edx
f010369f:	73 04                	jae    f01036a5 <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01036a1:	01 fa                	add    %edi,%edx
f01036a3:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01036a5:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01036a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01036ab:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01036b0:	39 f2                	cmp    %esi,%edx
f01036b2:	7d 4b                	jge    f01036ff <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f01036b4:	83 c2 01             	add    $0x1,%edx
f01036b7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01036ba:	89 d0                	mov    %edx,%eax
f01036bc:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01036bf:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01036c2:	8d 14 97             	lea    (%edi,%edx,4),%edx
f01036c5:	eb 04                	jmp    f01036cb <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01036c7:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01036cb:	39 c6                	cmp    %eax,%esi
f01036cd:	7e 2b                	jle    f01036fa <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01036cf:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01036d3:	83 c0 01             	add    $0x1,%eax
f01036d6:	83 c2 0c             	add    $0xc,%edx
f01036d9:	80 f9 a0             	cmp    $0xa0,%cl
f01036dc:	74 e9                	je     f01036c7 <debuginfo_eip+0x1ff>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01036de:	b8 00 00 00 00       	mov    $0x0,%eax
f01036e3:	eb 1a                	jmp    f01036ff <debuginfo_eip+0x237>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01036e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036ea:	eb 13                	jmp    f01036ff <debuginfo_eip+0x237>
f01036ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036f1:	eb 0c                	jmp    f01036ff <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01036f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01036f8:	eb 05                	jmp    f01036ff <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01036fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01036ff:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103702:	5b                   	pop    %ebx
f0103703:	5e                   	pop    %esi
f0103704:	5f                   	pop    %edi
f0103705:	5d                   	pop    %ebp
f0103706:	c3                   	ret    

f0103707 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103707:	55                   	push   %ebp
f0103708:	89 e5                	mov    %esp,%ebp
f010370a:	57                   	push   %edi
f010370b:	56                   	push   %esi
f010370c:	53                   	push   %ebx
f010370d:	83 ec 1c             	sub    $0x1c,%esp
f0103710:	89 c7                	mov    %eax,%edi
f0103712:	89 d6                	mov    %edx,%esi
f0103714:	8b 45 08             	mov    0x8(%ebp),%eax
f0103717:	8b 55 0c             	mov    0xc(%ebp),%edx
f010371a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010371d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103720:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103723:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103728:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010372b:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010372e:	39 d3                	cmp    %edx,%ebx
f0103730:	72 05                	jb     f0103737 <printnum+0x30>
f0103732:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103735:	77 45                	ja     f010377c <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103737:	83 ec 0c             	sub    $0xc,%esp
f010373a:	ff 75 18             	pushl  0x18(%ebp)
f010373d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103740:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103743:	53                   	push   %ebx
f0103744:	ff 75 10             	pushl  0x10(%ebp)
f0103747:	83 ec 08             	sub    $0x8,%esp
f010374a:	ff 75 e4             	pushl  -0x1c(%ebp)
f010374d:	ff 75 e0             	pushl  -0x20(%ebp)
f0103750:	ff 75 dc             	pushl  -0x24(%ebp)
f0103753:	ff 75 d8             	pushl  -0x28(%ebp)
f0103756:	e8 35 09 00 00       	call   f0104090 <__udivdi3>
f010375b:	83 c4 18             	add    $0x18,%esp
f010375e:	52                   	push   %edx
f010375f:	50                   	push   %eax
f0103760:	89 f2                	mov    %esi,%edx
f0103762:	89 f8                	mov    %edi,%eax
f0103764:	e8 9e ff ff ff       	call   f0103707 <printnum>
f0103769:	83 c4 20             	add    $0x20,%esp
f010376c:	eb 18                	jmp    f0103786 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010376e:	83 ec 08             	sub    $0x8,%esp
f0103771:	56                   	push   %esi
f0103772:	ff 75 18             	pushl  0x18(%ebp)
f0103775:	ff d7                	call   *%edi
f0103777:	83 c4 10             	add    $0x10,%esp
f010377a:	eb 03                	jmp    f010377f <printnum+0x78>
f010377c:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f010377f:	83 eb 01             	sub    $0x1,%ebx
f0103782:	85 db                	test   %ebx,%ebx
f0103784:	7f e8                	jg     f010376e <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103786:	83 ec 08             	sub    $0x8,%esp
f0103789:	56                   	push   %esi
f010378a:	83 ec 04             	sub    $0x4,%esp
f010378d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103790:	ff 75 e0             	pushl  -0x20(%ebp)
f0103793:	ff 75 dc             	pushl  -0x24(%ebp)
f0103796:	ff 75 d8             	pushl  -0x28(%ebp)
f0103799:	e8 22 0a 00 00       	call   f01041c0 <__umoddi3>
f010379e:	83 c4 14             	add    $0x14,%esp
f01037a1:	0f be 80 a1 58 10 f0 	movsbl -0xfefa75f(%eax),%eax
f01037a8:	50                   	push   %eax
f01037a9:	ff d7                	call   *%edi
}
f01037ab:	83 c4 10             	add    $0x10,%esp
f01037ae:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01037b1:	5b                   	pop    %ebx
f01037b2:	5e                   	pop    %esi
f01037b3:	5f                   	pop    %edi
f01037b4:	5d                   	pop    %ebp
f01037b5:	c3                   	ret    

f01037b6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01037b6:	55                   	push   %ebp
f01037b7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01037b9:	83 fa 01             	cmp    $0x1,%edx
f01037bc:	7e 0e                	jle    f01037cc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01037be:	8b 10                	mov    (%eax),%edx
f01037c0:	8d 4a 08             	lea    0x8(%edx),%ecx
f01037c3:	89 08                	mov    %ecx,(%eax)
f01037c5:	8b 02                	mov    (%edx),%eax
f01037c7:	8b 52 04             	mov    0x4(%edx),%edx
f01037ca:	eb 22                	jmp    f01037ee <getuint+0x38>
	else if (lflag)
f01037cc:	85 d2                	test   %edx,%edx
f01037ce:	74 10                	je     f01037e0 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01037d0:	8b 10                	mov    (%eax),%edx
f01037d2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01037d5:	89 08                	mov    %ecx,(%eax)
f01037d7:	8b 02                	mov    (%edx),%eax
f01037d9:	ba 00 00 00 00       	mov    $0x0,%edx
f01037de:	eb 0e                	jmp    f01037ee <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01037e0:	8b 10                	mov    (%eax),%edx
f01037e2:	8d 4a 04             	lea    0x4(%edx),%ecx
f01037e5:	89 08                	mov    %ecx,(%eax)
f01037e7:	8b 02                	mov    (%edx),%eax
f01037e9:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01037ee:	5d                   	pop    %ebp
f01037ef:	c3                   	ret    

f01037f0 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01037f0:	55                   	push   %ebp
f01037f1:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01037f3:	83 fa 01             	cmp    $0x1,%edx
f01037f6:	7e 0e                	jle    f0103806 <getint+0x16>
		return va_arg(*ap, long long);
f01037f8:	8b 10                	mov    (%eax),%edx
f01037fa:	8d 4a 08             	lea    0x8(%edx),%ecx
f01037fd:	89 08                	mov    %ecx,(%eax)
f01037ff:	8b 02                	mov    (%edx),%eax
f0103801:	8b 52 04             	mov    0x4(%edx),%edx
f0103804:	eb 1a                	jmp    f0103820 <getint+0x30>
	else if (lflag)
f0103806:	85 d2                	test   %edx,%edx
f0103808:	74 0c                	je     f0103816 <getint+0x26>
		return va_arg(*ap, long);
f010380a:	8b 10                	mov    (%eax),%edx
f010380c:	8d 4a 04             	lea    0x4(%edx),%ecx
f010380f:	89 08                	mov    %ecx,(%eax)
f0103811:	8b 02                	mov    (%edx),%eax
f0103813:	99                   	cltd   
f0103814:	eb 0a                	jmp    f0103820 <getint+0x30>
	else
		return va_arg(*ap, int);
f0103816:	8b 10                	mov    (%eax),%edx
f0103818:	8d 4a 04             	lea    0x4(%edx),%ecx
f010381b:	89 08                	mov    %ecx,(%eax)
f010381d:	8b 02                	mov    (%edx),%eax
f010381f:	99                   	cltd   
}
f0103820:	5d                   	pop    %ebp
f0103821:	c3                   	ret    

f0103822 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103822:	55                   	push   %ebp
f0103823:	89 e5                	mov    %esp,%ebp
f0103825:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103828:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010382c:	8b 10                	mov    (%eax),%edx
f010382e:	3b 50 04             	cmp    0x4(%eax),%edx
f0103831:	73 0a                	jae    f010383d <sprintputch+0x1b>
		*b->buf++ = ch;
f0103833:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103836:	89 08                	mov    %ecx,(%eax)
f0103838:	8b 45 08             	mov    0x8(%ebp),%eax
f010383b:	88 02                	mov    %al,(%edx)
}
f010383d:	5d                   	pop    %ebp
f010383e:	c3                   	ret    

f010383f <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010383f:	55                   	push   %ebp
f0103840:	89 e5                	mov    %esp,%ebp
f0103842:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103845:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103848:	50                   	push   %eax
f0103849:	ff 75 10             	pushl  0x10(%ebp)
f010384c:	ff 75 0c             	pushl  0xc(%ebp)
f010384f:	ff 75 08             	pushl  0x8(%ebp)
f0103852:	e8 05 00 00 00       	call   f010385c <vprintfmt>
	va_end(ap);
}
f0103857:	83 c4 10             	add    $0x10,%esp
f010385a:	c9                   	leave  
f010385b:	c3                   	ret    

f010385c <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010385c:	55                   	push   %ebp
f010385d:	89 e5                	mov    %esp,%ebp
f010385f:	57                   	push   %edi
f0103860:	56                   	push   %esi
f0103861:	53                   	push   %ebx
f0103862:	83 ec 2c             	sub    $0x2c,%esp
f0103865:	8b 75 08             	mov    0x8(%ebp),%esi
f0103868:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010386b:	8b 7d 10             	mov    0x10(%ebp),%edi
f010386e:	eb 12                	jmp    f0103882 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103870:	85 c0                	test   %eax,%eax
f0103872:	0f 84 44 03 00 00    	je     f0103bbc <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0103878:	83 ec 08             	sub    $0x8,%esp
f010387b:	53                   	push   %ebx
f010387c:	50                   	push   %eax
f010387d:	ff d6                	call   *%esi
f010387f:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103882:	83 c7 01             	add    $0x1,%edi
f0103885:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103889:	83 f8 25             	cmp    $0x25,%eax
f010388c:	75 e2                	jne    f0103870 <vprintfmt+0x14>
f010388e:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103892:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103899:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01038a0:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01038a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01038ac:	eb 07                	jmp    f01038b5 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01038b1:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038b5:	8d 47 01             	lea    0x1(%edi),%eax
f01038b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038bb:	0f b6 07             	movzbl (%edi),%eax
f01038be:	0f b6 c8             	movzbl %al,%ecx
f01038c1:	83 e8 23             	sub    $0x23,%eax
f01038c4:	3c 55                	cmp    $0x55,%al
f01038c6:	0f 87 d5 02 00 00    	ja     f0103ba1 <vprintfmt+0x345>
f01038cc:	0f b6 c0             	movzbl %al,%eax
f01038cf:	ff 24 85 2c 59 10 f0 	jmp    *-0xfefa6d4(,%eax,4)
f01038d6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01038d9:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01038dd:	eb d6                	jmp    f01038b5 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01038df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01038e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01038e7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01038ea:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01038ed:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f01038f1:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f01038f4:	8d 51 d0             	lea    -0x30(%ecx),%edx
f01038f7:	83 fa 09             	cmp    $0x9,%edx
f01038fa:	77 39                	ja     f0103935 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01038fc:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01038ff:	eb e9                	jmp    f01038ea <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103901:	8b 45 14             	mov    0x14(%ebp),%eax
f0103904:	8d 48 04             	lea    0x4(%eax),%ecx
f0103907:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010390a:	8b 00                	mov    (%eax),%eax
f010390c:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010390f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103912:	eb 27                	jmp    f010393b <vprintfmt+0xdf>
f0103914:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103917:	85 c0                	test   %eax,%eax
f0103919:	b9 00 00 00 00       	mov    $0x0,%ecx
f010391e:	0f 49 c8             	cmovns %eax,%ecx
f0103921:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103924:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103927:	eb 8c                	jmp    f01038b5 <vprintfmt+0x59>
f0103929:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010392c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103933:	eb 80                	jmp    f01038b5 <vprintfmt+0x59>
f0103935:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103938:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f010393b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010393f:	0f 89 70 ff ff ff    	jns    f01038b5 <vprintfmt+0x59>
				width = precision, precision = -1;
f0103945:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103948:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010394b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103952:	e9 5e ff ff ff       	jmp    f01038b5 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103957:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010395a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010395d:	e9 53 ff ff ff       	jmp    f01038b5 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103962:	8b 45 14             	mov    0x14(%ebp),%eax
f0103965:	8d 50 04             	lea    0x4(%eax),%edx
f0103968:	89 55 14             	mov    %edx,0x14(%ebp)
f010396b:	83 ec 08             	sub    $0x8,%esp
f010396e:	53                   	push   %ebx
f010396f:	ff 30                	pushl  (%eax)
f0103971:	ff d6                	call   *%esi
			break;
f0103973:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103976:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103979:	e9 04 ff ff ff       	jmp    f0103882 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010397e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103981:	8d 50 04             	lea    0x4(%eax),%edx
f0103984:	89 55 14             	mov    %edx,0x14(%ebp)
f0103987:	8b 00                	mov    (%eax),%eax
f0103989:	99                   	cltd   
f010398a:	31 d0                	xor    %edx,%eax
f010398c:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010398e:	83 f8 06             	cmp    $0x6,%eax
f0103991:	7f 0b                	jg     f010399e <vprintfmt+0x142>
f0103993:	8b 14 85 84 5a 10 f0 	mov    -0xfefa57c(,%eax,4),%edx
f010399a:	85 d2                	test   %edx,%edx
f010399c:	75 18                	jne    f01039b6 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f010399e:	50                   	push   %eax
f010399f:	68 b9 58 10 f0       	push   $0xf01058b9
f01039a4:	53                   	push   %ebx
f01039a5:	56                   	push   %esi
f01039a6:	e8 94 fe ff ff       	call   f010383f <printfmt>
f01039ab:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01039b1:	e9 cc fe ff ff       	jmp    f0103882 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f01039b6:	52                   	push   %edx
f01039b7:	68 8c 50 10 f0       	push   $0xf010508c
f01039bc:	53                   	push   %ebx
f01039bd:	56                   	push   %esi
f01039be:	e8 7c fe ff ff       	call   f010383f <printfmt>
f01039c3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039c6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01039c9:	e9 b4 fe ff ff       	jmp    f0103882 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01039ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01039d1:	8d 50 04             	lea    0x4(%eax),%edx
f01039d4:	89 55 14             	mov    %edx,0x14(%ebp)
f01039d7:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01039d9:	85 ff                	test   %edi,%edi
f01039db:	b8 b2 58 10 f0       	mov    $0xf01058b2,%eax
f01039e0:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01039e3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01039e7:	0f 8e 94 00 00 00    	jle    f0103a81 <vprintfmt+0x225>
f01039ed:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01039f1:	0f 84 98 00 00 00    	je     f0103a8f <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f01039f7:	83 ec 08             	sub    $0x8,%esp
f01039fa:	ff 75 d0             	pushl  -0x30(%ebp)
f01039fd:	57                   	push   %edi
f01039fe:	e8 1a 03 00 00       	call   f0103d1d <strnlen>
f0103a03:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103a06:	29 c1                	sub    %eax,%ecx
f0103a08:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0103a0b:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0103a0e:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0103a12:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a15:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103a18:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103a1a:	eb 0f                	jmp    f0103a2b <vprintfmt+0x1cf>
					putch(padc, putdat);
f0103a1c:	83 ec 08             	sub    $0x8,%esp
f0103a1f:	53                   	push   %ebx
f0103a20:	ff 75 e0             	pushl  -0x20(%ebp)
f0103a23:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103a25:	83 ef 01             	sub    $0x1,%edi
f0103a28:	83 c4 10             	add    $0x10,%esp
f0103a2b:	85 ff                	test   %edi,%edi
f0103a2d:	7f ed                	jg     f0103a1c <vprintfmt+0x1c0>
f0103a2f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103a32:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0103a35:	85 c9                	test   %ecx,%ecx
f0103a37:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a3c:	0f 49 c1             	cmovns %ecx,%eax
f0103a3f:	29 c1                	sub    %eax,%ecx
f0103a41:	89 75 08             	mov    %esi,0x8(%ebp)
f0103a44:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103a47:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a4a:	89 cb                	mov    %ecx,%ebx
f0103a4c:	eb 4d                	jmp    f0103a9b <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103a4e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103a52:	74 1b                	je     f0103a6f <vprintfmt+0x213>
f0103a54:	0f be c0             	movsbl %al,%eax
f0103a57:	83 e8 20             	sub    $0x20,%eax
f0103a5a:	83 f8 5e             	cmp    $0x5e,%eax
f0103a5d:	76 10                	jbe    f0103a6f <vprintfmt+0x213>
					putch('?', putdat);
f0103a5f:	83 ec 08             	sub    $0x8,%esp
f0103a62:	ff 75 0c             	pushl  0xc(%ebp)
f0103a65:	6a 3f                	push   $0x3f
f0103a67:	ff 55 08             	call   *0x8(%ebp)
f0103a6a:	83 c4 10             	add    $0x10,%esp
f0103a6d:	eb 0d                	jmp    f0103a7c <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0103a6f:	83 ec 08             	sub    $0x8,%esp
f0103a72:	ff 75 0c             	pushl  0xc(%ebp)
f0103a75:	52                   	push   %edx
f0103a76:	ff 55 08             	call   *0x8(%ebp)
f0103a79:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103a7c:	83 eb 01             	sub    $0x1,%ebx
f0103a7f:	eb 1a                	jmp    f0103a9b <vprintfmt+0x23f>
f0103a81:	89 75 08             	mov    %esi,0x8(%ebp)
f0103a84:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103a87:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a8a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103a8d:	eb 0c                	jmp    f0103a9b <vprintfmt+0x23f>
f0103a8f:	89 75 08             	mov    %esi,0x8(%ebp)
f0103a92:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0103a95:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103a98:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0103a9b:	83 c7 01             	add    $0x1,%edi
f0103a9e:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103aa2:	0f be d0             	movsbl %al,%edx
f0103aa5:	85 d2                	test   %edx,%edx
f0103aa7:	74 23                	je     f0103acc <vprintfmt+0x270>
f0103aa9:	85 f6                	test   %esi,%esi
f0103aab:	78 a1                	js     f0103a4e <vprintfmt+0x1f2>
f0103aad:	83 ee 01             	sub    $0x1,%esi
f0103ab0:	79 9c                	jns    f0103a4e <vprintfmt+0x1f2>
f0103ab2:	89 df                	mov    %ebx,%edi
f0103ab4:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ab7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aba:	eb 18                	jmp    f0103ad4 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103abc:	83 ec 08             	sub    $0x8,%esp
f0103abf:	53                   	push   %ebx
f0103ac0:	6a 20                	push   $0x20
f0103ac2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ac4:	83 ef 01             	sub    $0x1,%edi
f0103ac7:	83 c4 10             	add    $0x10,%esp
f0103aca:	eb 08                	jmp    f0103ad4 <vprintfmt+0x278>
f0103acc:	89 df                	mov    %ebx,%edi
f0103ace:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ad1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ad4:	85 ff                	test   %edi,%edi
f0103ad6:	7f e4                	jg     f0103abc <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ad8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103adb:	e9 a2 fd ff ff       	jmp    f0103882 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0103ae0:	8d 45 14             	lea    0x14(%ebp),%eax
f0103ae3:	e8 08 fd ff ff       	call   f01037f0 <getint>
f0103ae8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103aeb:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103aee:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103af3:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103af7:	79 74                	jns    f0103b6d <vprintfmt+0x311>
				putch('-', putdat);
f0103af9:	83 ec 08             	sub    $0x8,%esp
f0103afc:	53                   	push   %ebx
f0103afd:	6a 2d                	push   $0x2d
f0103aff:	ff d6                	call   *%esi
				num = -(long long) num;
f0103b01:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103b04:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103b07:	f7 d8                	neg    %eax
f0103b09:	83 d2 00             	adc    $0x0,%edx
f0103b0c:	f7 da                	neg    %edx
f0103b0e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0103b11:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103b16:	eb 55                	jmp    f0103b6d <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103b18:	8d 45 14             	lea    0x14(%ebp),%eax
f0103b1b:	e8 96 fc ff ff       	call   f01037b6 <getuint>
			base = 10;
f0103b20:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0103b25:	eb 46                	jmp    f0103b6d <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f0103b27:	8d 45 14             	lea    0x14(%ebp),%eax
f0103b2a:	e8 87 fc ff ff       	call   f01037b6 <getuint>
			base = 8;
f0103b2f:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0103b34:	eb 37                	jmp    f0103b6d <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f0103b36:	83 ec 08             	sub    $0x8,%esp
f0103b39:	53                   	push   %ebx
f0103b3a:	6a 30                	push   $0x30
f0103b3c:	ff d6                	call   *%esi
			putch('x', putdat);
f0103b3e:	83 c4 08             	add    $0x8,%esp
f0103b41:	53                   	push   %ebx
f0103b42:	6a 78                	push   $0x78
f0103b44:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103b46:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b49:	8d 50 04             	lea    0x4(%eax),%edx
f0103b4c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103b4f:	8b 00                	mov    (%eax),%eax
f0103b51:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0103b56:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103b59:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103b5e:	eb 0d                	jmp    f0103b6d <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103b60:	8d 45 14             	lea    0x14(%ebp),%eax
f0103b63:	e8 4e fc ff ff       	call   f01037b6 <getuint>
			base = 16;
f0103b68:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103b6d:	83 ec 0c             	sub    $0xc,%esp
f0103b70:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0103b74:	57                   	push   %edi
f0103b75:	ff 75 e0             	pushl  -0x20(%ebp)
f0103b78:	51                   	push   %ecx
f0103b79:	52                   	push   %edx
f0103b7a:	50                   	push   %eax
f0103b7b:	89 da                	mov    %ebx,%edx
f0103b7d:	89 f0                	mov    %esi,%eax
f0103b7f:	e8 83 fb ff ff       	call   f0103707 <printnum>
			break;
f0103b84:	83 c4 20             	add    $0x20,%esp
f0103b87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103b8a:	e9 f3 fc ff ff       	jmp    f0103882 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103b8f:	83 ec 08             	sub    $0x8,%esp
f0103b92:	53                   	push   %ebx
f0103b93:	51                   	push   %ecx
f0103b94:	ff d6                	call   *%esi
			break;
f0103b96:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103b9c:	e9 e1 fc ff ff       	jmp    f0103882 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103ba1:	83 ec 08             	sub    $0x8,%esp
f0103ba4:	53                   	push   %ebx
f0103ba5:	6a 25                	push   $0x25
f0103ba7:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103ba9:	83 c4 10             	add    $0x10,%esp
f0103bac:	eb 03                	jmp    f0103bb1 <vprintfmt+0x355>
f0103bae:	83 ef 01             	sub    $0x1,%edi
f0103bb1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103bb5:	75 f7                	jne    f0103bae <vprintfmt+0x352>
f0103bb7:	e9 c6 fc ff ff       	jmp    f0103882 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0103bbc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103bbf:	5b                   	pop    %ebx
f0103bc0:	5e                   	pop    %esi
f0103bc1:	5f                   	pop    %edi
f0103bc2:	5d                   	pop    %ebp
f0103bc3:	c3                   	ret    

f0103bc4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103bc4:	55                   	push   %ebp
f0103bc5:	89 e5                	mov    %esp,%ebp
f0103bc7:	83 ec 18             	sub    $0x18,%esp
f0103bca:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bcd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103bd0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103bd3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103bd7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103bda:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103be1:	85 c0                	test   %eax,%eax
f0103be3:	74 26                	je     f0103c0b <vsnprintf+0x47>
f0103be5:	85 d2                	test   %edx,%edx
f0103be7:	7e 22                	jle    f0103c0b <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103be9:	ff 75 14             	pushl  0x14(%ebp)
f0103bec:	ff 75 10             	pushl  0x10(%ebp)
f0103bef:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103bf2:	50                   	push   %eax
f0103bf3:	68 22 38 10 f0       	push   $0xf0103822
f0103bf8:	e8 5f fc ff ff       	call   f010385c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103bfd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103c00:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103c03:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c06:	83 c4 10             	add    $0x10,%esp
f0103c09:	eb 05                	jmp    f0103c10 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103c0b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103c10:	c9                   	leave  
f0103c11:	c3                   	ret    

f0103c12 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103c12:	55                   	push   %ebp
f0103c13:	89 e5                	mov    %esp,%ebp
f0103c15:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103c18:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103c1b:	50                   	push   %eax
f0103c1c:	ff 75 10             	pushl  0x10(%ebp)
f0103c1f:	ff 75 0c             	pushl  0xc(%ebp)
f0103c22:	ff 75 08             	pushl  0x8(%ebp)
f0103c25:	e8 9a ff ff ff       	call   f0103bc4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103c2a:	c9                   	leave  
f0103c2b:	c3                   	ret    

f0103c2c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103c2c:	55                   	push   %ebp
f0103c2d:	89 e5                	mov    %esp,%ebp
f0103c2f:	57                   	push   %edi
f0103c30:	56                   	push   %esi
f0103c31:	53                   	push   %ebx
f0103c32:	83 ec 0c             	sub    $0xc,%esp
f0103c35:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103c38:	85 c0                	test   %eax,%eax
f0103c3a:	74 11                	je     f0103c4d <readline+0x21>
		cprintf("%s", prompt);
f0103c3c:	83 ec 08             	sub    $0x8,%esp
f0103c3f:	50                   	push   %eax
f0103c40:	68 8c 50 10 f0       	push   $0xf010508c
f0103c45:	e8 85 f3 ff ff       	call   f0102fcf <cprintf>
f0103c4a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0103c4d:	83 ec 0c             	sub    $0xc,%esp
f0103c50:	6a 00                	push   $0x0
f0103c52:	e8 ed ca ff ff       	call   f0100744 <iscons>
f0103c57:	89 c7                	mov    %eax,%edi
f0103c59:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103c5c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103c61:	e8 cd ca ff ff       	call   f0100733 <getchar>
f0103c66:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103c68:	85 c0                	test   %eax,%eax
f0103c6a:	79 18                	jns    f0103c84 <readline+0x58>
			cprintf("read error: %e\n", c);
f0103c6c:	83 ec 08             	sub    $0x8,%esp
f0103c6f:	50                   	push   %eax
f0103c70:	68 a0 5a 10 f0       	push   $0xf0105aa0
f0103c75:	e8 55 f3 ff ff       	call   f0102fcf <cprintf>
			return NULL;
f0103c7a:	83 c4 10             	add    $0x10,%esp
f0103c7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c82:	eb 79                	jmp    f0103cfd <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103c84:	83 f8 08             	cmp    $0x8,%eax
f0103c87:	0f 94 c2             	sete   %dl
f0103c8a:	83 f8 7f             	cmp    $0x7f,%eax
f0103c8d:	0f 94 c0             	sete   %al
f0103c90:	08 c2                	or     %al,%dl
f0103c92:	74 1a                	je     f0103cae <readline+0x82>
f0103c94:	85 f6                	test   %esi,%esi
f0103c96:	7e 16                	jle    f0103cae <readline+0x82>
			if (echoing)
f0103c98:	85 ff                	test   %edi,%edi
f0103c9a:	74 0d                	je     f0103ca9 <readline+0x7d>
				cputchar('\b');
f0103c9c:	83 ec 0c             	sub    $0xc,%esp
f0103c9f:	6a 08                	push   $0x8
f0103ca1:	e8 7d ca ff ff       	call   f0100723 <cputchar>
f0103ca6:	83 c4 10             	add    $0x10,%esp
			i--;
f0103ca9:	83 ee 01             	sub    $0x1,%esi
f0103cac:	eb b3                	jmp    f0103c61 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103cae:	83 fb 1f             	cmp    $0x1f,%ebx
f0103cb1:	7e 23                	jle    f0103cd6 <readline+0xaa>
f0103cb3:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103cb9:	7f 1b                	jg     f0103cd6 <readline+0xaa>
			if (echoing)
f0103cbb:	85 ff                	test   %edi,%edi
f0103cbd:	74 0c                	je     f0103ccb <readline+0x9f>
				cputchar(c);
f0103cbf:	83 ec 0c             	sub    $0xc,%esp
f0103cc2:	53                   	push   %ebx
f0103cc3:	e8 5b ca ff ff       	call   f0100723 <cputchar>
f0103cc8:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0103ccb:	88 9e a0 56 19 f0    	mov    %bl,-0xfe6a960(%esi)
f0103cd1:	8d 76 01             	lea    0x1(%esi),%esi
f0103cd4:	eb 8b                	jmp    f0103c61 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0103cd6:	83 fb 0a             	cmp    $0xa,%ebx
f0103cd9:	74 05                	je     f0103ce0 <readline+0xb4>
f0103cdb:	83 fb 0d             	cmp    $0xd,%ebx
f0103cde:	75 81                	jne    f0103c61 <readline+0x35>
			if (echoing)
f0103ce0:	85 ff                	test   %edi,%edi
f0103ce2:	74 0d                	je     f0103cf1 <readline+0xc5>
				cputchar('\n');
f0103ce4:	83 ec 0c             	sub    $0xc,%esp
f0103ce7:	6a 0a                	push   $0xa
f0103ce9:	e8 35 ca ff ff       	call   f0100723 <cputchar>
f0103cee:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0103cf1:	c6 86 a0 56 19 f0 00 	movb   $0x0,-0xfe6a960(%esi)
			return buf;
f0103cf8:	b8 a0 56 19 f0       	mov    $0xf01956a0,%eax
		}
	}
}
f0103cfd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d00:	5b                   	pop    %ebx
f0103d01:	5e                   	pop    %esi
f0103d02:	5f                   	pop    %edi
f0103d03:	5d                   	pop    %ebp
f0103d04:	c3                   	ret    

f0103d05 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103d05:	55                   	push   %ebp
f0103d06:	89 e5                	mov    %esp,%ebp
f0103d08:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103d0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d10:	eb 03                	jmp    f0103d15 <strlen+0x10>
		n++;
f0103d12:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103d15:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103d19:	75 f7                	jne    f0103d12 <strlen+0xd>
		n++;
	return n;
}
f0103d1b:	5d                   	pop    %ebp
f0103d1c:	c3                   	ret    

f0103d1d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103d1d:	55                   	push   %ebp
f0103d1e:	89 e5                	mov    %esp,%ebp
f0103d20:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103d23:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103d26:	ba 00 00 00 00       	mov    $0x0,%edx
f0103d2b:	eb 03                	jmp    f0103d30 <strnlen+0x13>
		n++;
f0103d2d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103d30:	39 c2                	cmp    %eax,%edx
f0103d32:	74 08                	je     f0103d3c <strnlen+0x1f>
f0103d34:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103d38:	75 f3                	jne    f0103d2d <strnlen+0x10>
f0103d3a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103d3c:	5d                   	pop    %ebp
f0103d3d:	c3                   	ret    

f0103d3e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103d3e:	55                   	push   %ebp
f0103d3f:	89 e5                	mov    %esp,%ebp
f0103d41:	53                   	push   %ebx
f0103d42:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d45:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103d48:	89 c2                	mov    %eax,%edx
f0103d4a:	83 c2 01             	add    $0x1,%edx
f0103d4d:	83 c1 01             	add    $0x1,%ecx
f0103d50:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0103d54:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103d57:	84 db                	test   %bl,%bl
f0103d59:	75 ef                	jne    f0103d4a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103d5b:	5b                   	pop    %ebx
f0103d5c:	5d                   	pop    %ebp
f0103d5d:	c3                   	ret    

f0103d5e <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103d5e:	55                   	push   %ebp
f0103d5f:	89 e5                	mov    %esp,%ebp
f0103d61:	53                   	push   %ebx
f0103d62:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103d65:	53                   	push   %ebx
f0103d66:	e8 9a ff ff ff       	call   f0103d05 <strlen>
f0103d6b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103d6e:	ff 75 0c             	pushl  0xc(%ebp)
f0103d71:	01 d8                	add    %ebx,%eax
f0103d73:	50                   	push   %eax
f0103d74:	e8 c5 ff ff ff       	call   f0103d3e <strcpy>
	return dst;
}
f0103d79:	89 d8                	mov    %ebx,%eax
f0103d7b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103d7e:	c9                   	leave  
f0103d7f:	c3                   	ret    

f0103d80 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103d80:	55                   	push   %ebp
f0103d81:	89 e5                	mov    %esp,%ebp
f0103d83:	56                   	push   %esi
f0103d84:	53                   	push   %ebx
f0103d85:	8b 75 08             	mov    0x8(%ebp),%esi
f0103d88:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103d8b:	89 f3                	mov    %esi,%ebx
f0103d8d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103d90:	89 f2                	mov    %esi,%edx
f0103d92:	eb 0f                	jmp    f0103da3 <strncpy+0x23>
		*dst++ = *src;
f0103d94:	83 c2 01             	add    $0x1,%edx
f0103d97:	0f b6 01             	movzbl (%ecx),%eax
f0103d9a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103d9d:	80 39 01             	cmpb   $0x1,(%ecx)
f0103da0:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103da3:	39 da                	cmp    %ebx,%edx
f0103da5:	75 ed                	jne    f0103d94 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103da7:	89 f0                	mov    %esi,%eax
f0103da9:	5b                   	pop    %ebx
f0103daa:	5e                   	pop    %esi
f0103dab:	5d                   	pop    %ebp
f0103dac:	c3                   	ret    

f0103dad <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103dad:	55                   	push   %ebp
f0103dae:	89 e5                	mov    %esp,%ebp
f0103db0:	56                   	push   %esi
f0103db1:	53                   	push   %ebx
f0103db2:	8b 75 08             	mov    0x8(%ebp),%esi
f0103db5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103db8:	8b 55 10             	mov    0x10(%ebp),%edx
f0103dbb:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103dbd:	85 d2                	test   %edx,%edx
f0103dbf:	74 21                	je     f0103de2 <strlcpy+0x35>
f0103dc1:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0103dc5:	89 f2                	mov    %esi,%edx
f0103dc7:	eb 09                	jmp    f0103dd2 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103dc9:	83 c2 01             	add    $0x1,%edx
f0103dcc:	83 c1 01             	add    $0x1,%ecx
f0103dcf:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103dd2:	39 c2                	cmp    %eax,%edx
f0103dd4:	74 09                	je     f0103ddf <strlcpy+0x32>
f0103dd6:	0f b6 19             	movzbl (%ecx),%ebx
f0103dd9:	84 db                	test   %bl,%bl
f0103ddb:	75 ec                	jne    f0103dc9 <strlcpy+0x1c>
f0103ddd:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103ddf:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103de2:	29 f0                	sub    %esi,%eax
}
f0103de4:	5b                   	pop    %ebx
f0103de5:	5e                   	pop    %esi
f0103de6:	5d                   	pop    %ebp
f0103de7:	c3                   	ret    

f0103de8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103de8:	55                   	push   %ebp
f0103de9:	89 e5                	mov    %esp,%ebp
f0103deb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103dee:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103df1:	eb 06                	jmp    f0103df9 <strcmp+0x11>
		p++, q++;
f0103df3:	83 c1 01             	add    $0x1,%ecx
f0103df6:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103df9:	0f b6 01             	movzbl (%ecx),%eax
f0103dfc:	84 c0                	test   %al,%al
f0103dfe:	74 04                	je     f0103e04 <strcmp+0x1c>
f0103e00:	3a 02                	cmp    (%edx),%al
f0103e02:	74 ef                	je     f0103df3 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e04:	0f b6 c0             	movzbl %al,%eax
f0103e07:	0f b6 12             	movzbl (%edx),%edx
f0103e0a:	29 d0                	sub    %edx,%eax
}
f0103e0c:	5d                   	pop    %ebp
f0103e0d:	c3                   	ret    

f0103e0e <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103e0e:	55                   	push   %ebp
f0103e0f:	89 e5                	mov    %esp,%ebp
f0103e11:	53                   	push   %ebx
f0103e12:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e15:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e18:	89 c3                	mov    %eax,%ebx
f0103e1a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103e1d:	eb 06                	jmp    f0103e25 <strncmp+0x17>
		n--, p++, q++;
f0103e1f:	83 c0 01             	add    $0x1,%eax
f0103e22:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103e25:	39 d8                	cmp    %ebx,%eax
f0103e27:	74 15                	je     f0103e3e <strncmp+0x30>
f0103e29:	0f b6 08             	movzbl (%eax),%ecx
f0103e2c:	84 c9                	test   %cl,%cl
f0103e2e:	74 04                	je     f0103e34 <strncmp+0x26>
f0103e30:	3a 0a                	cmp    (%edx),%cl
f0103e32:	74 eb                	je     f0103e1f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103e34:	0f b6 00             	movzbl (%eax),%eax
f0103e37:	0f b6 12             	movzbl (%edx),%edx
f0103e3a:	29 d0                	sub    %edx,%eax
f0103e3c:	eb 05                	jmp    f0103e43 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103e3e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103e43:	5b                   	pop    %ebx
f0103e44:	5d                   	pop    %ebp
f0103e45:	c3                   	ret    

f0103e46 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103e46:	55                   	push   %ebp
f0103e47:	89 e5                	mov    %esp,%ebp
f0103e49:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e4c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e50:	eb 07                	jmp    f0103e59 <strchr+0x13>
		if (*s == c)
f0103e52:	38 ca                	cmp    %cl,%dl
f0103e54:	74 0f                	je     f0103e65 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103e56:	83 c0 01             	add    $0x1,%eax
f0103e59:	0f b6 10             	movzbl (%eax),%edx
f0103e5c:	84 d2                	test   %dl,%dl
f0103e5e:	75 f2                	jne    f0103e52 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103e60:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103e65:	5d                   	pop    %ebp
f0103e66:	c3                   	ret    

f0103e67 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103e67:	55                   	push   %ebp
f0103e68:	89 e5                	mov    %esp,%ebp
f0103e6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e6d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103e71:	eb 03                	jmp    f0103e76 <strfind+0xf>
f0103e73:	83 c0 01             	add    $0x1,%eax
f0103e76:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0103e79:	38 ca                	cmp    %cl,%dl
f0103e7b:	74 04                	je     f0103e81 <strfind+0x1a>
f0103e7d:	84 d2                	test   %dl,%dl
f0103e7f:	75 f2                	jne    f0103e73 <strfind+0xc>
			break;
	return (char *) s;
}
f0103e81:	5d                   	pop    %ebp
f0103e82:	c3                   	ret    

f0103e83 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103e83:	55                   	push   %ebp
f0103e84:	89 e5                	mov    %esp,%ebp
f0103e86:	57                   	push   %edi
f0103e87:	56                   	push   %esi
f0103e88:	53                   	push   %ebx
f0103e89:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e8c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0103e8f:	85 c9                	test   %ecx,%ecx
f0103e91:	74 37                	je     f0103eca <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103e93:	f6 c2 03             	test   $0x3,%dl
f0103e96:	75 2a                	jne    f0103ec2 <memset+0x3f>
f0103e98:	f6 c1 03             	test   $0x3,%cl
f0103e9b:	75 25                	jne    f0103ec2 <memset+0x3f>
		c &= 0xFF;
f0103e9d:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103ea1:	89 df                	mov    %ebx,%edi
f0103ea3:	c1 e7 08             	shl    $0x8,%edi
f0103ea6:	89 de                	mov    %ebx,%esi
f0103ea8:	c1 e6 18             	shl    $0x18,%esi
f0103eab:	89 d8                	mov    %ebx,%eax
f0103ead:	c1 e0 10             	shl    $0x10,%eax
f0103eb0:	09 f0                	or     %esi,%eax
f0103eb2:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f0103eb4:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103eb7:	89 f8                	mov    %edi,%eax
f0103eb9:	09 d8                	or     %ebx,%eax
f0103ebb:	89 d7                	mov    %edx,%edi
f0103ebd:	fc                   	cld    
f0103ebe:	f3 ab                	rep stos %eax,%es:(%edi)
f0103ec0:	eb 08                	jmp    f0103eca <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103ec2:	89 d7                	mov    %edx,%edi
f0103ec4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ec7:	fc                   	cld    
f0103ec8:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f0103eca:	89 d0                	mov    %edx,%eax
f0103ecc:	5b                   	pop    %ebx
f0103ecd:	5e                   	pop    %esi
f0103ece:	5f                   	pop    %edi
f0103ecf:	5d                   	pop    %ebp
f0103ed0:	c3                   	ret    

f0103ed1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103ed1:	55                   	push   %ebp
f0103ed2:	89 e5                	mov    %esp,%ebp
f0103ed4:	57                   	push   %edi
f0103ed5:	56                   	push   %esi
f0103ed6:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ed9:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103edc:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103edf:	39 c6                	cmp    %eax,%esi
f0103ee1:	73 35                	jae    f0103f18 <memmove+0x47>
f0103ee3:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103ee6:	39 d0                	cmp    %edx,%eax
f0103ee8:	73 2e                	jae    f0103f18 <memmove+0x47>
		s += n;
		d += n;
f0103eea:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103eed:	89 d6                	mov    %edx,%esi
f0103eef:	09 fe                	or     %edi,%esi
f0103ef1:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103ef7:	75 13                	jne    f0103f0c <memmove+0x3b>
f0103ef9:	f6 c1 03             	test   $0x3,%cl
f0103efc:	75 0e                	jne    f0103f0c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103efe:	83 ef 04             	sub    $0x4,%edi
f0103f01:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103f04:	c1 e9 02             	shr    $0x2,%ecx
f0103f07:	fd                   	std    
f0103f08:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f0a:	eb 09                	jmp    f0103f15 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103f0c:	83 ef 01             	sub    $0x1,%edi
f0103f0f:	8d 72 ff             	lea    -0x1(%edx),%esi
f0103f12:	fd                   	std    
f0103f13:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103f15:	fc                   	cld    
f0103f16:	eb 1d                	jmp    f0103f35 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103f18:	89 f2                	mov    %esi,%edx
f0103f1a:	09 c2                	or     %eax,%edx
f0103f1c:	f6 c2 03             	test   $0x3,%dl
f0103f1f:	75 0f                	jne    f0103f30 <memmove+0x5f>
f0103f21:	f6 c1 03             	test   $0x3,%cl
f0103f24:	75 0a                	jne    f0103f30 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0103f26:	c1 e9 02             	shr    $0x2,%ecx
f0103f29:	89 c7                	mov    %eax,%edi
f0103f2b:	fc                   	cld    
f0103f2c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103f2e:	eb 05                	jmp    f0103f35 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103f30:	89 c7                	mov    %eax,%edi
f0103f32:	fc                   	cld    
f0103f33:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103f35:	5e                   	pop    %esi
f0103f36:	5f                   	pop    %edi
f0103f37:	5d                   	pop    %ebp
f0103f38:	c3                   	ret    

f0103f39 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103f39:	55                   	push   %ebp
f0103f3a:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103f3c:	ff 75 10             	pushl  0x10(%ebp)
f0103f3f:	ff 75 0c             	pushl  0xc(%ebp)
f0103f42:	ff 75 08             	pushl  0x8(%ebp)
f0103f45:	e8 87 ff ff ff       	call   f0103ed1 <memmove>
}
f0103f4a:	c9                   	leave  
f0103f4b:	c3                   	ret    

f0103f4c <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103f4c:	55                   	push   %ebp
f0103f4d:	89 e5                	mov    %esp,%ebp
f0103f4f:	56                   	push   %esi
f0103f50:	53                   	push   %ebx
f0103f51:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f54:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103f57:	89 c6                	mov    %eax,%esi
f0103f59:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f5c:	eb 1a                	jmp    f0103f78 <memcmp+0x2c>
		if (*s1 != *s2)
f0103f5e:	0f b6 08             	movzbl (%eax),%ecx
f0103f61:	0f b6 1a             	movzbl (%edx),%ebx
f0103f64:	38 d9                	cmp    %bl,%cl
f0103f66:	74 0a                	je     f0103f72 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103f68:	0f b6 c1             	movzbl %cl,%eax
f0103f6b:	0f b6 db             	movzbl %bl,%ebx
f0103f6e:	29 d8                	sub    %ebx,%eax
f0103f70:	eb 0f                	jmp    f0103f81 <memcmp+0x35>
		s1++, s2++;
f0103f72:	83 c0 01             	add    $0x1,%eax
f0103f75:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103f78:	39 f0                	cmp    %esi,%eax
f0103f7a:	75 e2                	jne    f0103f5e <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103f7c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103f81:	5b                   	pop    %ebx
f0103f82:	5e                   	pop    %esi
f0103f83:	5d                   	pop    %ebp
f0103f84:	c3                   	ret    

f0103f85 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103f85:	55                   	push   %ebp
f0103f86:	89 e5                	mov    %esp,%ebp
f0103f88:	53                   	push   %ebx
f0103f89:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103f8c:	89 c1                	mov    %eax,%ecx
f0103f8e:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0103f91:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103f95:	eb 0a                	jmp    f0103fa1 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103f97:	0f b6 10             	movzbl (%eax),%edx
f0103f9a:	39 da                	cmp    %ebx,%edx
f0103f9c:	74 07                	je     f0103fa5 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103f9e:	83 c0 01             	add    $0x1,%eax
f0103fa1:	39 c8                	cmp    %ecx,%eax
f0103fa3:	72 f2                	jb     f0103f97 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103fa5:	5b                   	pop    %ebx
f0103fa6:	5d                   	pop    %ebp
f0103fa7:	c3                   	ret    

f0103fa8 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103fa8:	55                   	push   %ebp
f0103fa9:	89 e5                	mov    %esp,%ebp
f0103fab:	57                   	push   %edi
f0103fac:	56                   	push   %esi
f0103fad:	53                   	push   %ebx
f0103fae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fb1:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103fb4:	eb 03                	jmp    f0103fb9 <strtol+0x11>
		s++;
f0103fb6:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103fb9:	0f b6 01             	movzbl (%ecx),%eax
f0103fbc:	3c 20                	cmp    $0x20,%al
f0103fbe:	74 f6                	je     f0103fb6 <strtol+0xe>
f0103fc0:	3c 09                	cmp    $0x9,%al
f0103fc2:	74 f2                	je     f0103fb6 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103fc4:	3c 2b                	cmp    $0x2b,%al
f0103fc6:	75 0a                	jne    f0103fd2 <strtol+0x2a>
		s++;
f0103fc8:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103fcb:	bf 00 00 00 00       	mov    $0x0,%edi
f0103fd0:	eb 11                	jmp    f0103fe3 <strtol+0x3b>
f0103fd2:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103fd7:	3c 2d                	cmp    $0x2d,%al
f0103fd9:	75 08                	jne    f0103fe3 <strtol+0x3b>
		s++, neg = 1;
f0103fdb:	83 c1 01             	add    $0x1,%ecx
f0103fde:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103fe3:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103fe9:	75 15                	jne    f0104000 <strtol+0x58>
f0103feb:	80 39 30             	cmpb   $0x30,(%ecx)
f0103fee:	75 10                	jne    f0104000 <strtol+0x58>
f0103ff0:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0103ff4:	75 7c                	jne    f0104072 <strtol+0xca>
		s += 2, base = 16;
f0103ff6:	83 c1 02             	add    $0x2,%ecx
f0103ff9:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103ffe:	eb 16                	jmp    f0104016 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104000:	85 db                	test   %ebx,%ebx
f0104002:	75 12                	jne    f0104016 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104004:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104009:	80 39 30             	cmpb   $0x30,(%ecx)
f010400c:	75 08                	jne    f0104016 <strtol+0x6e>
		s++, base = 8;
f010400e:	83 c1 01             	add    $0x1,%ecx
f0104011:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0104016:	b8 00 00 00 00       	mov    $0x0,%eax
f010401b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010401e:	0f b6 11             	movzbl (%ecx),%edx
f0104021:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104024:	89 f3                	mov    %esi,%ebx
f0104026:	80 fb 09             	cmp    $0x9,%bl
f0104029:	77 08                	ja     f0104033 <strtol+0x8b>
			dig = *s - '0';
f010402b:	0f be d2             	movsbl %dl,%edx
f010402e:	83 ea 30             	sub    $0x30,%edx
f0104031:	eb 22                	jmp    f0104055 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104033:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104036:	89 f3                	mov    %esi,%ebx
f0104038:	80 fb 19             	cmp    $0x19,%bl
f010403b:	77 08                	ja     f0104045 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010403d:	0f be d2             	movsbl %dl,%edx
f0104040:	83 ea 57             	sub    $0x57,%edx
f0104043:	eb 10                	jmp    f0104055 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0104045:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104048:	89 f3                	mov    %esi,%ebx
f010404a:	80 fb 19             	cmp    $0x19,%bl
f010404d:	77 16                	ja     f0104065 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010404f:	0f be d2             	movsbl %dl,%edx
f0104052:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0104055:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104058:	7d 0b                	jge    f0104065 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010405a:	83 c1 01             	add    $0x1,%ecx
f010405d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104061:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104063:	eb b9                	jmp    f010401e <strtol+0x76>

	if (endptr)
f0104065:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104069:	74 0d                	je     f0104078 <strtol+0xd0>
		*endptr = (char *) s;
f010406b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010406e:	89 0e                	mov    %ecx,(%esi)
f0104070:	eb 06                	jmp    f0104078 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104072:	85 db                	test   %ebx,%ebx
f0104074:	74 98                	je     f010400e <strtol+0x66>
f0104076:	eb 9e                	jmp    f0104016 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0104078:	89 c2                	mov    %eax,%edx
f010407a:	f7 da                	neg    %edx
f010407c:	85 ff                	test   %edi,%edi
f010407e:	0f 45 c2             	cmovne %edx,%eax
}
f0104081:	5b                   	pop    %ebx
f0104082:	5e                   	pop    %esi
f0104083:	5f                   	pop    %edi
f0104084:	5d                   	pop    %ebp
f0104085:	c3                   	ret    
f0104086:	66 90                	xchg   %ax,%ax
f0104088:	66 90                	xchg   %ax,%ax
f010408a:	66 90                	xchg   %ax,%ax
f010408c:	66 90                	xchg   %ax,%ax
f010408e:	66 90                	xchg   %ax,%ax

f0104090 <__udivdi3>:
f0104090:	55                   	push   %ebp
f0104091:	57                   	push   %edi
f0104092:	56                   	push   %esi
f0104093:	53                   	push   %ebx
f0104094:	83 ec 1c             	sub    $0x1c,%esp
f0104097:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010409b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010409f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01040a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01040a7:	85 f6                	test   %esi,%esi
f01040a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01040ad:	89 ca                	mov    %ecx,%edx
f01040af:	89 f8                	mov    %edi,%eax
f01040b1:	75 3d                	jne    f01040f0 <__udivdi3+0x60>
f01040b3:	39 cf                	cmp    %ecx,%edi
f01040b5:	0f 87 c5 00 00 00    	ja     f0104180 <__udivdi3+0xf0>
f01040bb:	85 ff                	test   %edi,%edi
f01040bd:	89 fd                	mov    %edi,%ebp
f01040bf:	75 0b                	jne    f01040cc <__udivdi3+0x3c>
f01040c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01040c6:	31 d2                	xor    %edx,%edx
f01040c8:	f7 f7                	div    %edi
f01040ca:	89 c5                	mov    %eax,%ebp
f01040cc:	89 c8                	mov    %ecx,%eax
f01040ce:	31 d2                	xor    %edx,%edx
f01040d0:	f7 f5                	div    %ebp
f01040d2:	89 c1                	mov    %eax,%ecx
f01040d4:	89 d8                	mov    %ebx,%eax
f01040d6:	89 cf                	mov    %ecx,%edi
f01040d8:	f7 f5                	div    %ebp
f01040da:	89 c3                	mov    %eax,%ebx
f01040dc:	89 d8                	mov    %ebx,%eax
f01040de:	89 fa                	mov    %edi,%edx
f01040e0:	83 c4 1c             	add    $0x1c,%esp
f01040e3:	5b                   	pop    %ebx
f01040e4:	5e                   	pop    %esi
f01040e5:	5f                   	pop    %edi
f01040e6:	5d                   	pop    %ebp
f01040e7:	c3                   	ret    
f01040e8:	90                   	nop
f01040e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040f0:	39 ce                	cmp    %ecx,%esi
f01040f2:	77 74                	ja     f0104168 <__udivdi3+0xd8>
f01040f4:	0f bd fe             	bsr    %esi,%edi
f01040f7:	83 f7 1f             	xor    $0x1f,%edi
f01040fa:	0f 84 98 00 00 00    	je     f0104198 <__udivdi3+0x108>
f0104100:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104105:	89 f9                	mov    %edi,%ecx
f0104107:	89 c5                	mov    %eax,%ebp
f0104109:	29 fb                	sub    %edi,%ebx
f010410b:	d3 e6                	shl    %cl,%esi
f010410d:	89 d9                	mov    %ebx,%ecx
f010410f:	d3 ed                	shr    %cl,%ebp
f0104111:	89 f9                	mov    %edi,%ecx
f0104113:	d3 e0                	shl    %cl,%eax
f0104115:	09 ee                	or     %ebp,%esi
f0104117:	89 d9                	mov    %ebx,%ecx
f0104119:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010411d:	89 d5                	mov    %edx,%ebp
f010411f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104123:	d3 ed                	shr    %cl,%ebp
f0104125:	89 f9                	mov    %edi,%ecx
f0104127:	d3 e2                	shl    %cl,%edx
f0104129:	89 d9                	mov    %ebx,%ecx
f010412b:	d3 e8                	shr    %cl,%eax
f010412d:	09 c2                	or     %eax,%edx
f010412f:	89 d0                	mov    %edx,%eax
f0104131:	89 ea                	mov    %ebp,%edx
f0104133:	f7 f6                	div    %esi
f0104135:	89 d5                	mov    %edx,%ebp
f0104137:	89 c3                	mov    %eax,%ebx
f0104139:	f7 64 24 0c          	mull   0xc(%esp)
f010413d:	39 d5                	cmp    %edx,%ebp
f010413f:	72 10                	jb     f0104151 <__udivdi3+0xc1>
f0104141:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104145:	89 f9                	mov    %edi,%ecx
f0104147:	d3 e6                	shl    %cl,%esi
f0104149:	39 c6                	cmp    %eax,%esi
f010414b:	73 07                	jae    f0104154 <__udivdi3+0xc4>
f010414d:	39 d5                	cmp    %edx,%ebp
f010414f:	75 03                	jne    f0104154 <__udivdi3+0xc4>
f0104151:	83 eb 01             	sub    $0x1,%ebx
f0104154:	31 ff                	xor    %edi,%edi
f0104156:	89 d8                	mov    %ebx,%eax
f0104158:	89 fa                	mov    %edi,%edx
f010415a:	83 c4 1c             	add    $0x1c,%esp
f010415d:	5b                   	pop    %ebx
f010415e:	5e                   	pop    %esi
f010415f:	5f                   	pop    %edi
f0104160:	5d                   	pop    %ebp
f0104161:	c3                   	ret    
f0104162:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104168:	31 ff                	xor    %edi,%edi
f010416a:	31 db                	xor    %ebx,%ebx
f010416c:	89 d8                	mov    %ebx,%eax
f010416e:	89 fa                	mov    %edi,%edx
f0104170:	83 c4 1c             	add    $0x1c,%esp
f0104173:	5b                   	pop    %ebx
f0104174:	5e                   	pop    %esi
f0104175:	5f                   	pop    %edi
f0104176:	5d                   	pop    %ebp
f0104177:	c3                   	ret    
f0104178:	90                   	nop
f0104179:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104180:	89 d8                	mov    %ebx,%eax
f0104182:	f7 f7                	div    %edi
f0104184:	31 ff                	xor    %edi,%edi
f0104186:	89 c3                	mov    %eax,%ebx
f0104188:	89 d8                	mov    %ebx,%eax
f010418a:	89 fa                	mov    %edi,%edx
f010418c:	83 c4 1c             	add    $0x1c,%esp
f010418f:	5b                   	pop    %ebx
f0104190:	5e                   	pop    %esi
f0104191:	5f                   	pop    %edi
f0104192:	5d                   	pop    %ebp
f0104193:	c3                   	ret    
f0104194:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104198:	39 ce                	cmp    %ecx,%esi
f010419a:	72 0c                	jb     f01041a8 <__udivdi3+0x118>
f010419c:	31 db                	xor    %ebx,%ebx
f010419e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01041a2:	0f 87 34 ff ff ff    	ja     f01040dc <__udivdi3+0x4c>
f01041a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01041ad:	e9 2a ff ff ff       	jmp    f01040dc <__udivdi3+0x4c>
f01041b2:	66 90                	xchg   %ax,%ax
f01041b4:	66 90                	xchg   %ax,%ax
f01041b6:	66 90                	xchg   %ax,%ax
f01041b8:	66 90                	xchg   %ax,%ax
f01041ba:	66 90                	xchg   %ax,%ax
f01041bc:	66 90                	xchg   %ax,%ax
f01041be:	66 90                	xchg   %ax,%ax

f01041c0 <__umoddi3>:
f01041c0:	55                   	push   %ebp
f01041c1:	57                   	push   %edi
f01041c2:	56                   	push   %esi
f01041c3:	53                   	push   %ebx
f01041c4:	83 ec 1c             	sub    $0x1c,%esp
f01041c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01041cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01041cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01041d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01041d7:	85 d2                	test   %edx,%edx
f01041d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01041dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01041e1:	89 f3                	mov    %esi,%ebx
f01041e3:	89 3c 24             	mov    %edi,(%esp)
f01041e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01041ea:	75 1c                	jne    f0104208 <__umoddi3+0x48>
f01041ec:	39 f7                	cmp    %esi,%edi
f01041ee:	76 50                	jbe    f0104240 <__umoddi3+0x80>
f01041f0:	89 c8                	mov    %ecx,%eax
f01041f2:	89 f2                	mov    %esi,%edx
f01041f4:	f7 f7                	div    %edi
f01041f6:	89 d0                	mov    %edx,%eax
f01041f8:	31 d2                	xor    %edx,%edx
f01041fa:	83 c4 1c             	add    $0x1c,%esp
f01041fd:	5b                   	pop    %ebx
f01041fe:	5e                   	pop    %esi
f01041ff:	5f                   	pop    %edi
f0104200:	5d                   	pop    %ebp
f0104201:	c3                   	ret    
f0104202:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104208:	39 f2                	cmp    %esi,%edx
f010420a:	89 d0                	mov    %edx,%eax
f010420c:	77 52                	ja     f0104260 <__umoddi3+0xa0>
f010420e:	0f bd ea             	bsr    %edx,%ebp
f0104211:	83 f5 1f             	xor    $0x1f,%ebp
f0104214:	75 5a                	jne    f0104270 <__umoddi3+0xb0>
f0104216:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010421a:	0f 82 e0 00 00 00    	jb     f0104300 <__umoddi3+0x140>
f0104220:	39 0c 24             	cmp    %ecx,(%esp)
f0104223:	0f 86 d7 00 00 00    	jbe    f0104300 <__umoddi3+0x140>
f0104229:	8b 44 24 08          	mov    0x8(%esp),%eax
f010422d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104231:	83 c4 1c             	add    $0x1c,%esp
f0104234:	5b                   	pop    %ebx
f0104235:	5e                   	pop    %esi
f0104236:	5f                   	pop    %edi
f0104237:	5d                   	pop    %ebp
f0104238:	c3                   	ret    
f0104239:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104240:	85 ff                	test   %edi,%edi
f0104242:	89 fd                	mov    %edi,%ebp
f0104244:	75 0b                	jne    f0104251 <__umoddi3+0x91>
f0104246:	b8 01 00 00 00       	mov    $0x1,%eax
f010424b:	31 d2                	xor    %edx,%edx
f010424d:	f7 f7                	div    %edi
f010424f:	89 c5                	mov    %eax,%ebp
f0104251:	89 f0                	mov    %esi,%eax
f0104253:	31 d2                	xor    %edx,%edx
f0104255:	f7 f5                	div    %ebp
f0104257:	89 c8                	mov    %ecx,%eax
f0104259:	f7 f5                	div    %ebp
f010425b:	89 d0                	mov    %edx,%eax
f010425d:	eb 99                	jmp    f01041f8 <__umoddi3+0x38>
f010425f:	90                   	nop
f0104260:	89 c8                	mov    %ecx,%eax
f0104262:	89 f2                	mov    %esi,%edx
f0104264:	83 c4 1c             	add    $0x1c,%esp
f0104267:	5b                   	pop    %ebx
f0104268:	5e                   	pop    %esi
f0104269:	5f                   	pop    %edi
f010426a:	5d                   	pop    %ebp
f010426b:	c3                   	ret    
f010426c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104270:	8b 34 24             	mov    (%esp),%esi
f0104273:	bf 20 00 00 00       	mov    $0x20,%edi
f0104278:	89 e9                	mov    %ebp,%ecx
f010427a:	29 ef                	sub    %ebp,%edi
f010427c:	d3 e0                	shl    %cl,%eax
f010427e:	89 f9                	mov    %edi,%ecx
f0104280:	89 f2                	mov    %esi,%edx
f0104282:	d3 ea                	shr    %cl,%edx
f0104284:	89 e9                	mov    %ebp,%ecx
f0104286:	09 c2                	or     %eax,%edx
f0104288:	89 d8                	mov    %ebx,%eax
f010428a:	89 14 24             	mov    %edx,(%esp)
f010428d:	89 f2                	mov    %esi,%edx
f010428f:	d3 e2                	shl    %cl,%edx
f0104291:	89 f9                	mov    %edi,%ecx
f0104293:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104297:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010429b:	d3 e8                	shr    %cl,%eax
f010429d:	89 e9                	mov    %ebp,%ecx
f010429f:	89 c6                	mov    %eax,%esi
f01042a1:	d3 e3                	shl    %cl,%ebx
f01042a3:	89 f9                	mov    %edi,%ecx
f01042a5:	89 d0                	mov    %edx,%eax
f01042a7:	d3 e8                	shr    %cl,%eax
f01042a9:	89 e9                	mov    %ebp,%ecx
f01042ab:	09 d8                	or     %ebx,%eax
f01042ad:	89 d3                	mov    %edx,%ebx
f01042af:	89 f2                	mov    %esi,%edx
f01042b1:	f7 34 24             	divl   (%esp)
f01042b4:	89 d6                	mov    %edx,%esi
f01042b6:	d3 e3                	shl    %cl,%ebx
f01042b8:	f7 64 24 04          	mull   0x4(%esp)
f01042bc:	39 d6                	cmp    %edx,%esi
f01042be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01042c2:	89 d1                	mov    %edx,%ecx
f01042c4:	89 c3                	mov    %eax,%ebx
f01042c6:	72 08                	jb     f01042d0 <__umoddi3+0x110>
f01042c8:	75 11                	jne    f01042db <__umoddi3+0x11b>
f01042ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01042ce:	73 0b                	jae    f01042db <__umoddi3+0x11b>
f01042d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01042d4:	1b 14 24             	sbb    (%esp),%edx
f01042d7:	89 d1                	mov    %edx,%ecx
f01042d9:	89 c3                	mov    %eax,%ebx
f01042db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01042df:	29 da                	sub    %ebx,%edx
f01042e1:	19 ce                	sbb    %ecx,%esi
f01042e3:	89 f9                	mov    %edi,%ecx
f01042e5:	89 f0                	mov    %esi,%eax
f01042e7:	d3 e0                	shl    %cl,%eax
f01042e9:	89 e9                	mov    %ebp,%ecx
f01042eb:	d3 ea                	shr    %cl,%edx
f01042ed:	89 e9                	mov    %ebp,%ecx
f01042ef:	d3 ee                	shr    %cl,%esi
f01042f1:	09 d0                	or     %edx,%eax
f01042f3:	89 f2                	mov    %esi,%edx
f01042f5:	83 c4 1c             	add    $0x1c,%esp
f01042f8:	5b                   	pop    %ebx
f01042f9:	5e                   	pop    %esi
f01042fa:	5f                   	pop    %edi
f01042fb:	5d                   	pop    %ebp
f01042fc:	c3                   	ret    
f01042fd:	8d 76 00             	lea    0x0(%esi),%esi
f0104300:	29 f9                	sub    %edi,%ecx
f0104302:	19 d6                	sbb    %edx,%esi
f0104304:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104308:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010430c:	e9 18 ff ff ff       	jmp    f0104229 <__umoddi3+0x69>
