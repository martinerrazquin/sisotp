
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
f010004f:	b8 90 78 19 f0       	mov    $0xf0197890,%eax
f0100054:	2d 80 59 19 f0       	sub    $0xf0195980,%eax
f0100059:	50                   	push   %eax
f010005a:	6a 00                	push   $0x0
f010005c:	68 80 59 19 f0       	push   $0xf0195980
f0100061:	e8 23 44 00 00       	call   f0104489 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100066:	e8 8d 06 00 00       	call   f01006f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006b:	83 c4 08             	add    $0x8,%esp
f010006e:	68 ac 1a 00 00       	push   $0x1aac
f0100073:	68 20 49 10 f0       	push   $0xf0104920
f0100078:	e8 05 30 00 00       	call   f0103082 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f010007d:	e8 44 25 00 00       	call   f01025c6 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100082:	e8 c3 2b 00 00       	call   f0102c4a <env_init>
	trap_init();
f0100087:	e8 ad 30 00 00       	call   f0103139 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f010008c:	83 c4 08             	add    $0x8,%esp
f010008f:	6a 00                	push   $0x0
f0100091:	68 ba ed 12 f0       	push   $0xf012edba
f0100096:	e8 dd 2c 00 00       	call   f0102d78 <env_create>
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*
	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f010009b:	83 c4 04             	add    $0x4,%esp
f010009e:	ff 35 c8 5b 19 f0    	pushl  0xf0195bc8
f01000a4:	e8 9f 2e 00 00       	call   f0102f48 <env_run>

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
f01000b1:	83 3d 80 78 19 f0 00 	cmpl   $0x0,0xf0197880
f01000b8:	75 37                	jne    f01000f1 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000ba:	89 35 80 78 19 f0    	mov    %esi,0xf0197880

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
f01000ce:	68 5c 49 10 f0       	push   $0xf010495c
f01000d3:	e8 aa 2f 00 00       	call   f0103082 <cprintf>
	vcprintf(fmt, ap);
f01000d8:	83 c4 08             	add    $0x8,%esp
f01000db:	53                   	push   %ebx
f01000dc:	56                   	push   %esi
f01000dd:	e8 7a 2f 00 00       	call   f010305c <vcprintf>
	cprintf("\n>>>\n");
f01000e2:	c7 04 24 3b 49 10 f0 	movl   $0xf010493b,(%esp)
f01000e9:	e8 94 2f 00 00       	call   f0103082 <cprintf>
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
f0100110:	68 41 49 10 f0       	push   $0xf0104941
f0100115:	e8 68 2f 00 00       	call   f0103082 <cprintf>
	vcprintf(fmt, ap);
f010011a:	83 c4 08             	add    $0x8,%esp
f010011d:	53                   	push   %ebx
f010011e:	ff 75 10             	pushl  0x10(%ebp)
f0100121:	e8 36 2f 00 00       	call   f010305c <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 0e 5b 10 f0 	movl   $0xf0105b0e,(%esp)
f010012d:	e8 50 2f 00 00       	call   f0103082 <cprintf>
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
f0100259:	0f 95 05 b4 5b 19 f0 	setne  0xf0195bb4
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
f01002f9:	c7 05 b0 5b 19 f0 b4 	movl   $0x3b4,0xf0195bb0
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
f0100313:	c7 05 b0 5b 19 f0 d4 	movl   $0x3d4,0xf0195bb0
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
f0100324:	8b 35 b0 5b 19 f0    	mov    0xf0195bb0,%esi
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
f010035c:	89 0d ac 5b 19 f0    	mov    %ecx,0xf0195bac
	crt_pos = pos;
f0100362:	0f b6 c0             	movzbl %al,%eax
f0100365:	09 c3                	or     %eax,%ebx
f0100367:	66 89 1d a8 5b 19 f0 	mov    %bx,0xf0195ba8
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
f0100385:	8b 0d a4 5b 19 f0    	mov    0xf0195ba4,%ecx
f010038b:	8d 51 01             	lea    0x1(%ecx),%edx
f010038e:	89 15 a4 5b 19 f0    	mov    %edx,0xf0195ba4
f0100394:	88 81 a0 59 19 f0    	mov    %al,-0xfe6a660(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010039a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003a0:	75 0a                	jne    f01003ac <cons_intr+0x36>
			cons.wpos = 0;
f01003a2:	c7 05 a4 5b 19 f0 00 	movl   $0x0,0xf0195ba4
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
f01003e8:	83 0d 80 59 19 f0 40 	orl    $0x40,0xf0195980
		return 0;
f01003ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01003f4:	e9 e7 00 00 00       	jmp    f01004e0 <kbd_proc_data+0x127>
	} else if (data & 0x80) {
f01003f9:	84 c0                	test   %al,%al
f01003fb:	79 38                	jns    f0100435 <kbd_proc_data+0x7c>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003fd:	8b 0d 80 59 19 f0    	mov    0xf0195980,%ecx
f0100403:	89 cb                	mov    %ecx,%ebx
f0100405:	83 e3 40             	and    $0x40,%ebx
f0100408:	89 c2                	mov    %eax,%edx
f010040a:	83 e2 7f             	and    $0x7f,%edx
f010040d:	85 db                	test   %ebx,%ebx
f010040f:	0f 44 c2             	cmove  %edx,%eax
		shift &= ~(shiftcode[data] | E0ESC);
f0100412:	0f b6 c0             	movzbl %al,%eax
f0100415:	0f b6 80 e0 4a 10 f0 	movzbl -0xfefb520(%eax),%eax
f010041c:	83 c8 40             	or     $0x40,%eax
f010041f:	0f b6 c0             	movzbl %al,%eax
f0100422:	f7 d0                	not    %eax
f0100424:	21 c8                	and    %ecx,%eax
f0100426:	a3 80 59 19 f0       	mov    %eax,0xf0195980
		return 0;
f010042b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100430:	e9 ab 00 00 00       	jmp    f01004e0 <kbd_proc_data+0x127>
	} else if (shift & E0ESC) {
f0100435:	8b 15 80 59 19 f0    	mov    0xf0195980,%edx
f010043b:	f6 c2 40             	test   $0x40,%dl
f010043e:	74 0c                	je     f010044c <kbd_proc_data+0x93>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100440:	83 c8 80             	or     $0xffffff80,%eax
		shift &= ~E0ESC;
f0100443:	83 e2 bf             	and    $0xffffffbf,%edx
f0100446:	89 15 80 59 19 f0    	mov    %edx,0xf0195980
	}

	shift |= shiftcode[data];
f010044c:	0f b6 c0             	movzbl %al,%eax
	shift ^= togglecode[data];
f010044f:	0f b6 90 e0 4a 10 f0 	movzbl -0xfefb520(%eax),%edx
f0100456:	0b 15 80 59 19 f0    	or     0xf0195980,%edx
f010045c:	0f b6 88 e0 49 10 f0 	movzbl -0xfefb620(%eax),%ecx
f0100463:	31 ca                	xor    %ecx,%edx
f0100465:	89 15 80 59 19 f0    	mov    %edx,0xf0195980

	c = charcode[shift & (CTL | SHIFT)][data];
f010046b:	89 d1                	mov    %edx,%ecx
f010046d:	83 e1 03             	and    $0x3,%ecx
f0100470:	8b 0c 8d c0 49 10 f0 	mov    -0xfefb640(,%ecx,4),%ecx
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
f01004b0:	68 7c 49 10 f0       	push   $0xf010497c
f01004b5:	e8 c8 2b 00 00       	call   f0103082 <cprintf>
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
f0100526:	0f b7 15 a8 5b 19 f0 	movzwl 0xf0195ba8,%edx
f010052d:	66 85 d2             	test   %dx,%dx
f0100530:	0f 84 e4 00 00 00    	je     f010061a <cga_putc+0x135>
			crt_pos--;
f0100536:	83 ea 01             	sub    $0x1,%edx
f0100539:	66 89 15 a8 5b 19 f0 	mov    %dx,0xf0195ba8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100540:	0f b7 d2             	movzwl %dx,%edx
f0100543:	b0 00                	mov    $0x0,%al
f0100545:	83 c8 20             	or     $0x20,%eax
f0100548:	8b 0d ac 5b 19 f0    	mov    0xf0195bac,%ecx
f010054e:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100552:	eb 78                	jmp    f01005cc <cga_putc+0xe7>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100554:	66 83 05 a8 5b 19 f0 	addw   $0x50,0xf0195ba8
f010055b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010055c:	0f b7 05 a8 5b 19 f0 	movzwl 0xf0195ba8,%eax
f0100563:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100569:	c1 e8 16             	shr    $0x16,%eax
f010056c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010056f:	c1 e0 04             	shl    $0x4,%eax
f0100572:	66 a3 a8 5b 19 f0    	mov    %ax,0xf0195ba8
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
f01005ae:	0f b7 15 a8 5b 19 f0 	movzwl 0xf0195ba8,%edx
f01005b5:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005b8:	66 89 0d a8 5b 19 f0 	mov    %cx,0xf0195ba8
f01005bf:	0f b7 d2             	movzwl %dx,%edx
f01005c2:	8b 0d ac 5b 19 f0    	mov    0xf0195bac,%ecx
f01005c8:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005cc:	66 81 3d a8 5b 19 f0 	cmpw   $0x7cf,0xf0195ba8
f01005d3:	cf 07 
f01005d5:	76 43                	jbe    f010061a <cga_putc+0x135>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d7:	a1 ac 5b 19 f0       	mov    0xf0195bac,%eax
f01005dc:	83 ec 04             	sub    $0x4,%esp
f01005df:	68 00 0f 00 00       	push   $0xf00
f01005e4:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005ea:	52                   	push   %edx
f01005eb:	50                   	push   %eax
f01005ec:	e8 e6 3e 00 00       	call   f01044d7 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f1:	8b 15 ac 5b 19 f0    	mov    0xf0195bac,%edx
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
f0100612:	66 83 2d a8 5b 19 f0 	subw   $0x50,0xf0195ba8
f0100619:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010061a:	8b 3d b0 5b 19 f0    	mov    0xf0195bb0,%edi
f0100620:	ba 0e 00 00 00       	mov    $0xe,%edx
f0100625:	89 f8                	mov    %edi,%eax
f0100627:	e8 16 fb ff ff       	call   f0100142 <outb>
	outb(addr_6845 + 1, crt_pos >> 8);
f010062c:	0f b7 1d a8 5b 19 f0 	movzwl 0xf0195ba8,%ebx
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
f0100680:	80 3d b4 5b 19 f0 00 	cmpb   $0x0,0xf0195bb4
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
f01006be:	a1 a0 5b 19 f0       	mov    0xf0195ba0,%eax
f01006c3:	3b 05 a4 5b 19 f0    	cmp    0xf0195ba4,%eax
f01006c9:	74 26                	je     f01006f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01006cb:	8d 50 01             	lea    0x1(%eax),%edx
f01006ce:	89 15 a0 5b 19 f0    	mov    %edx,0xf0195ba0
f01006d4:	0f b6 88 a0 59 19 f0 	movzbl -0xfe6a660(%eax),%ecx
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
f01006e5:	c7 05 a0 5b 19 f0 00 	movl   $0x0,0xf0195ba0
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
f0100708:	80 3d b4 5b 19 f0 00 	cmpb   $0x0,0xf0195bb4
f010070f:	75 10                	jne    f0100721 <cons_init+0x29>
		cprintf("Serial port does not exist!\n");
f0100711:	83 ec 0c             	sub    $0xc,%esp
f0100714:	68 88 49 10 f0       	push   $0xf0104988
f0100719:	e8 64 29 00 00       	call   f0103082 <cprintf>
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
f0100754:	68 e0 4b 10 f0       	push   $0xf0104be0
f0100759:	68 fe 4b 10 f0       	push   $0xf0104bfe
f010075e:	68 03 4c 10 f0       	push   $0xf0104c03
f0100763:	e8 1a 29 00 00       	call   f0103082 <cprintf>
f0100768:	83 c4 0c             	add    $0xc,%esp
f010076b:	68 a0 4c 10 f0       	push   $0xf0104ca0
f0100770:	68 0c 4c 10 f0       	push   $0xf0104c0c
f0100775:	68 03 4c 10 f0       	push   $0xf0104c03
f010077a:	e8 03 29 00 00       	call   f0103082 <cprintf>
f010077f:	83 c4 0c             	add    $0xc,%esp
f0100782:	68 15 4c 10 f0       	push   $0xf0104c15
f0100787:	68 29 4c 10 f0       	push   $0xf0104c29
f010078c:	68 03 4c 10 f0       	push   $0xf0104c03
f0100791:	e8 ec 28 00 00       	call   f0103082 <cprintf>
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
f01007a3:	68 33 4c 10 f0       	push   $0xf0104c33
f01007a8:	e8 d5 28 00 00       	call   f0103082 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007ad:	83 c4 08             	add    $0x8,%esp
f01007b0:	68 0c 00 10 00       	push   $0x10000c
f01007b5:	68 c8 4c 10 f0       	push   $0xf0104cc8
f01007ba:	e8 c3 28 00 00       	call   f0103082 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007bf:	83 c4 0c             	add    $0xc,%esp
f01007c2:	68 0c 00 10 00       	push   $0x10000c
f01007c7:	68 0c 00 10 f0       	push   $0xf010000c
f01007cc:	68 f0 4c 10 f0       	push   $0xf0104cf0
f01007d1:	e8 ac 28 00 00       	call   f0103082 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007d6:	83 c4 0c             	add    $0xc,%esp
f01007d9:	68 11 49 10 00       	push   $0x104911
f01007de:	68 11 49 10 f0       	push   $0xf0104911
f01007e3:	68 14 4d 10 f0       	push   $0xf0104d14
f01007e8:	e8 95 28 00 00       	call   f0103082 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007ed:	83 c4 0c             	add    $0xc,%esp
f01007f0:	68 6e 59 19 00       	push   $0x19596e
f01007f5:	68 6e 59 19 f0       	push   $0xf019596e
f01007fa:	68 38 4d 10 f0       	push   $0xf0104d38
f01007ff:	e8 7e 28 00 00       	call   f0103082 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100804:	83 c4 0c             	add    $0xc,%esp
f0100807:	68 90 78 19 00       	push   $0x197890
f010080c:	68 90 78 19 f0       	push   $0xf0197890
f0100811:	68 5c 4d 10 f0       	push   $0xf0104d5c
f0100816:	e8 67 28 00 00       	call   f0103082 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010081b:	b8 8f 7c 19 f0       	mov    $0xf0197c8f,%eax
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
f010083c:	68 80 4d 10 f0       	push   $0xf0104d80
f0100841:	e8 3c 28 00 00       	call   f0103082 <cprintf>
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
f0100871:	68 ac 4d 10 f0       	push   $0xf0104dac
f0100876:	e8 07 28 00 00       	call   f0103082 <cprintf>
			*(uint32_t *)(ebp+8), *(uint32_t *)(ebp+12), *(uint32_t *)(ebp+16),
			*(uint32_t *)(ebp+20), *(uint32_t *)(ebp+24));
	debuginfo_eip(eip,&dbgi);
f010087b:	83 c4 18             	add    $0x18,%esp
f010087e:	57                   	push   %edi
f010087f:	56                   	push   %esi
f0100880:	e8 49 32 00 00       	call   f0103ace <debuginfo_eip>
	cprintf("       %s:%d: %.*s+%d\n", dbgi.eip_file, dbgi.eip_line, dbgi.eip_fn_namelen, 
f0100885:	83 c4 08             	add    $0x8,%esp
f0100888:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010088b:	56                   	push   %esi
f010088c:	ff 75 d8             	pushl  -0x28(%ebp)
f010088f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100892:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100895:	ff 75 d0             	pushl  -0x30(%ebp)
f0100898:	68 4c 4c 10 f0       	push   $0xf0104c4c
f010089d:	e8 e0 27 00 00       	call   f0103082 <cprintf>
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
f01008ec:	68 63 4c 10 f0       	push   $0xf0104c63
f01008f1:	e8 56 3b 00 00       	call   f010444c <strchr>
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
f010090e:	68 68 4c 10 f0       	push   $0xf0104c68
f0100913:	e8 6a 27 00 00       	call   f0103082 <cprintf>
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
f010093f:	68 63 4c 10 f0       	push   $0xf0104c63
f0100944:	e8 03 3b 00 00       	call   f010444c <strchr>
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
f010096e:	ff 34 85 40 4e 10 f0 	pushl  -0xfefb1c0(,%eax,4)
f0100975:	ff 75 a8             	pushl  -0x58(%ebp)
f0100978:	e8 71 3a 00 00       	call   f01043ee <strcmp>
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
f0100992:	ff 14 85 48 4e 10 f0 	call   *-0xfefb1b8(,%eax,4)
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
f01009ac:	68 85 4c 10 f0       	push   $0xf0104c85
f01009b1:	e8 cc 26 00 00       	call   f0103082 <cprintf>
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
f01009d0:	68 e0 4d 10 f0       	push   $0xf0104de0
f01009d5:	e8 a8 26 00 00       	call   f0103082 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009da:	c7 04 24 04 4e 10 f0 	movl   $0xf0104e04,(%esp)
f01009e1:	e8 9c 26 00 00       	call   f0103082 <cprintf>

	if (tf != NULL)
f01009e6:	83 c4 10             	add    $0x10,%esp
f01009e9:	85 db                	test   %ebx,%ebx
f01009eb:	74 0c                	je     f01009f9 <monitor+0x33>
		print_trapframe(tf);
f01009ed:	83 ec 0c             	sub    $0xc,%esp
f01009f0:	53                   	push   %ebx
f01009f1:	e8 28 2b 00 00       	call   f010351e <print_trapframe>
f01009f6:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009f9:	83 ec 0c             	sub    $0xc,%esp
f01009fc:	68 9b 4c 10 f0       	push   $0xf0104c9b
f0100a01:	e8 2c 38 00 00       	call   f0104232 <readline>
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
f0100a40:	2b 05 8c 78 19 f0    	sub    0xf019788c,%eax
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
f0100a59:	e8 aa 25 00 00       	call   f0103008 <mc146818_read>
f0100a5e:	89 c6                	mov    %eax,%esi
f0100a60:	83 c3 01             	add    $0x1,%ebx
f0100a63:	89 1c 24             	mov    %ebx,(%esp)
f0100a66:	e8 9d 25 00 00       	call   f0103008 <mc146818_read>
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
f0100abc:	89 15 84 78 19 f0    	mov    %edx,0xf0197884
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100ac2:	89 c2                	mov    %eax,%edx
f0100ac4:	29 da                	sub    %ebx,%edx
f0100ac6:	52                   	push   %edx
f0100ac7:	53                   	push   %ebx
f0100ac8:	50                   	push   %eax
f0100ac9:	68 64 4e 10 f0       	push   $0xf0104e64
f0100ace:	e8 af 25 00 00       	call   f0103082 <cprintf>
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
f0100ae9:	3b 1d 84 78 19 f0    	cmp    0xf0197884,%ebx
f0100aef:	72 0d                	jb     f0100afe <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100af1:	51                   	push   %ecx
f0100af2:	68 a0 4e 10 f0       	push   $0xf0104ea0
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
f0100b1b:	b8 4d 56 10 f0       	mov    $0xf010564d,%eax
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
f0100b58:	ba 32 03 00 00       	mov    $0x332,%edx
f0100b5d:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
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
f0100ba6:	68 c4 4e 10 f0       	push   $0xf0104ec4
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
f0100bb9:	83 3d b8 5b 19 f0 00 	cmpl   $0x0,0xf0195bb8
f0100bc0:	75 11                	jne    f0100bd3 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100bc2:	ba 8f 88 19 f0       	mov    $0xf019888f,%edx
f0100bc7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bcd:	89 15 b8 5b 19 f0    	mov    %edx,0xf0195bb8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n==0) return nextfree;
f0100bd3:	85 c0                	test   %eax,%eax
f0100bd5:	75 06                	jne    f0100bdd <boot_alloc+0x24>
f0100bd7:	a1 b8 5b 19 f0       	mov    0xf0195bb8,%eax
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
f0100be4:	8b 1d b8 5b 19 f0    	mov    0xf0195bb8,%ebx
	nextfree += ROUNDUP(n,PGSIZE);
f0100bea:	8d 88 ff 0f 00 00    	lea    0xfff(%eax),%ecx
f0100bf0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100bf6:	01 d9                	add    %ebx,%ecx
f0100bf8:	89 0d b8 5b 19 f0    	mov    %ecx,0xf0195bb8
	if (PADDR(nextfree)>npages*PGSIZE) panic("not enough memory\n");
f0100bfe:	ba 6e 00 00 00       	mov    $0x6e,%edx
f0100c03:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0100c08:	e8 8a ff ff ff       	call   f0100b97 <_paddr>
f0100c0d:	8b 15 84 78 19 f0    	mov    0xf0197884,%edx
f0100c13:	c1 e2 0c             	shl    $0xc,%edx
f0100c16:	39 d0                	cmp    %edx,%eax
f0100c18:	76 14                	jbe    f0100c2e <boot_alloc+0x75>
f0100c1a:	83 ec 04             	sub    $0x4,%esp
f0100c1d:	68 67 56 10 f0       	push   $0xf0105667
f0100c22:	6a 6e                	push   $0x6e
f0100c24:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100c3e:	8b 1d 88 78 19 f0    	mov    0xf0197888,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0100c44:	a1 84 78 19 f0       	mov    0xf0197884,%eax
f0100c49:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c4c:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0100c53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0100c5b:	a1 8c 78 19 f0       	mov    0xf019788c,%eax
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
f0100c7c:	ba f4 02 00 00       	mov    $0x2f4,%edx
f0100c81:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0100c86:	e8 0c ff ff ff       	call   f0100b97 <_paddr>
f0100c8b:	01 f0                	add    %esi,%eax
f0100c8d:	39 c7                	cmp    %eax,%edi
f0100c8f:	74 19                	je     f0100caa <check_kern_pgdir+0x75>
f0100c91:	68 e8 4e 10 f0       	push   $0xf0104ee8
f0100c96:	68 7a 56 10 f0       	push   $0xf010567a
f0100c9b:	68 f4 02 00 00       	push   $0x2f4
f0100ca0:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100cb5:	a1 c8 5b 19 f0       	mov    0xf0195bc8,%eax
f0100cba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cbd:	be 00 00 00 00       	mov    $0x0,%esi
f0100cc2:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
f0100cc8:	89 d8                	mov    %ebx,%eax
f0100cca:	e8 58 fe ff ff       	call   f0100b27 <check_va2pa>
f0100ccf:	89 c7                	mov    %eax,%edi
f0100cd1:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100cd4:	ba f9 02 00 00       	mov    $0x2f9,%edx
f0100cd9:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0100cde:	e8 b4 fe ff ff       	call   f0100b97 <_paddr>
f0100ce3:	01 f0                	add    %esi,%eax
f0100ce5:	39 c7                	cmp    %eax,%edi
f0100ce7:	74 19                	je     f0100d02 <check_kern_pgdir+0xcd>
f0100ce9:	68 1c 4f 10 f0       	push   $0xf0104f1c
f0100cee:	68 7a 56 10 f0       	push   $0xf010567a
f0100cf3:	68 f9 02 00 00       	push   $0x2f9
f0100cf8:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100d2e:	68 50 4f 10 f0       	push   $0xf0104f50
f0100d33:	68 7a 56 10 f0       	push   $0xf010567a
f0100d38:	68 fd 02 00 00       	push   $0x2fd
f0100d3d:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100d65:	b9 00 70 10 f0       	mov    $0xf0107000,%ecx
f0100d6a:	ba 01 03 00 00       	mov    $0x301,%edx
f0100d6f:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0100d74:	e8 1e fe ff ff       	call   f0100b97 <_paddr>
f0100d79:	01 f0                	add    %esi,%eax
f0100d7b:	39 c7                	cmp    %eax,%edi
f0100d7d:	74 19                	je     f0100d98 <check_kern_pgdir+0x163>
f0100d7f:	68 78 4f 10 f0       	push   $0xf0104f78
f0100d84:	68 7a 56 10 f0       	push   $0xf010567a
f0100d89:	68 01 03 00 00       	push   $0x301
f0100d8e:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100db7:	68 c0 4f 10 f0       	push   $0xf0104fc0
f0100dbc:	68 7a 56 10 f0       	push   $0xf010567a
f0100dc1:	68 02 03 00 00       	push   $0x302
f0100dc6:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100def:	68 8f 56 10 f0       	push   $0xf010568f
f0100df4:	68 7a 56 10 f0       	push   $0xf010567a
f0100df9:	68 0b 03 00 00       	push   $0x30b
f0100dfe:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100e1c:	68 8f 56 10 f0       	push   $0xf010568f
f0100e21:	68 7a 56 10 f0       	push   $0xf010567a
f0100e26:	68 0f 03 00 00       	push   $0x30f
f0100e2b:	68 5b 56 10 f0       	push   $0xf010565b
f0100e30:	e8 74 f2 ff ff       	call   f01000a9 <_panic>
				assert(pgdir[i] & PTE_W);
f0100e35:	f6 c2 02             	test   $0x2,%dl
f0100e38:	75 38                	jne    f0100e72 <check_kern_pgdir+0x23d>
f0100e3a:	68 a0 56 10 f0       	push   $0xf01056a0
f0100e3f:	68 7a 56 10 f0       	push   $0xf010567a
f0100e44:	68 10 03 00 00       	push   $0x310
f0100e49:	68 5b 56 10 f0       	push   $0xf010565b
f0100e4e:	e8 56 f2 ff ff       	call   f01000a9 <_panic>
			} else
				assert(pgdir[i] == 0);
f0100e53:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0100e57:	74 19                	je     f0100e72 <check_kern_pgdir+0x23d>
f0100e59:	68 b1 56 10 f0       	push   $0xf01056b1
f0100e5e:	68 7a 56 10 f0       	push   $0xf010567a
f0100e63:	68 12 03 00 00       	push   $0x312
f0100e68:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100e83:	68 f0 4f 10 f0       	push   $0xf0104ff0
f0100e88:	e8 f5 21 00 00       	call   f0103082 <cprintf>
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
f0100eb1:	68 10 50 10 f0       	push   $0xf0105010
f0100eb6:	68 64 02 00 00       	push   $0x264
f0100ebb:	68 5b 56 10 f0       	push   $0xf010565b
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
f0100f07:	a3 c0 5b 19 f0       	mov    %eax,0xf0195bc0
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
f0100f11:	8b 1d c0 5b 19 f0    	mov    0xf0195bc0,%ebx
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
f0100f3c:	e8 48 35 00 00       	call   f0104489 <memset>
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
f0100f57:	8b 1d c0 5b 19 f0    	mov    0xf0195bc0,%ebx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100f5d:	8b 35 8c 78 19 f0    	mov    0xf019788c,%esi
		assert(pp < pages + npages);
f0100f63:	a1 84 78 19 f0       	mov    0xf0197884,%eax
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
f0100f86:	68 bf 56 10 f0       	push   $0xf01056bf
f0100f8b:	68 7a 56 10 f0       	push   $0xf010567a
f0100f90:	68 7e 02 00 00       	push   $0x27e
f0100f95:	68 5b 56 10 f0       	push   $0xf010565b
f0100f9a:	e8 0a f1 ff ff       	call   f01000a9 <_panic>
		assert(pp < pages + npages);
f0100f9f:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f0100fa2:	72 19                	jb     f0100fbd <check_page_free_list+0x125>
f0100fa4:	68 cb 56 10 f0       	push   $0xf01056cb
f0100fa9:	68 7a 56 10 f0       	push   $0xf010567a
f0100fae:	68 7f 02 00 00       	push   $0x27f
f0100fb3:	68 5b 56 10 f0       	push   $0xf010565b
f0100fb8:	e8 ec f0 ff ff       	call   f01000a9 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100fbd:	89 d8                	mov    %ebx,%eax
f0100fbf:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100fc2:	a8 07                	test   $0x7,%al
f0100fc4:	74 19                	je     f0100fdf <check_page_free_list+0x147>
f0100fc6:	68 34 50 10 f0       	push   $0xf0105034
f0100fcb:	68 7a 56 10 f0       	push   $0xf010567a
f0100fd0:	68 80 02 00 00       	push   $0x280
f0100fd5:	68 5b 56 10 f0       	push   $0xf010565b
f0100fda:	e8 ca f0 ff ff       	call   f01000a9 <_panic>

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100fdf:	89 d8                	mov    %ebx,%eax
f0100fe1:	e8 57 fa ff ff       	call   f0100a3d <page2pa>
f0100fe6:	85 c0                	test   %eax,%eax
f0100fe8:	75 19                	jne    f0101003 <check_page_free_list+0x16b>
f0100fea:	68 df 56 10 f0       	push   $0xf01056df
f0100fef:	68 7a 56 10 f0       	push   $0xf010567a
f0100ff4:	68 83 02 00 00       	push   $0x283
f0100ff9:	68 5b 56 10 f0       	push   $0xf010565b
f0100ffe:	e8 a6 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101003:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101008:	75 19                	jne    f0101023 <check_page_free_list+0x18b>
f010100a:	68 f0 56 10 f0       	push   $0xf01056f0
f010100f:	68 7a 56 10 f0       	push   $0xf010567a
f0101014:	68 84 02 00 00       	push   $0x284
f0101019:	68 5b 56 10 f0       	push   $0xf010565b
f010101e:	e8 86 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0101023:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101028:	75 19                	jne    f0101043 <check_page_free_list+0x1ab>
f010102a:	68 68 50 10 f0       	push   $0xf0105068
f010102f:	68 7a 56 10 f0       	push   $0xf010567a
f0101034:	68 85 02 00 00       	push   $0x285
f0101039:	68 5b 56 10 f0       	push   $0xf010565b
f010103e:	e8 66 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101043:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0101048:	75 19                	jne    f0101063 <check_page_free_list+0x1cb>
f010104a:	68 09 57 10 f0       	push   $0xf0105709
f010104f:	68 7a 56 10 f0       	push   $0xf010567a
f0101054:	68 86 02 00 00       	push   $0x286
f0101059:	68 5b 56 10 f0       	push   $0xf010565b
f010105e:	e8 46 f0 ff ff       	call   f01000a9 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101063:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101068:	76 25                	jbe    f010108f <check_page_free_list+0x1f7>
f010106a:	89 d8                	mov    %ebx,%eax
f010106c:	e8 98 fa ff ff       	call   f0100b09 <page2kva>
f0101071:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0101074:	76 1e                	jbe    f0101094 <check_page_free_list+0x1fc>
f0101076:	68 8c 50 10 f0       	push   $0xf010508c
f010107b:	68 7a 56 10 f0       	push   $0xf010567a
f0101080:	68 87 02 00 00       	push   $0x287
f0101085:	68 5b 56 10 f0       	push   $0xf010565b
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
f01010a6:	68 23 57 10 f0       	push   $0xf0105723
f01010ab:	68 7a 56 10 f0       	push   $0xf010567a
f01010b0:	68 8f 02 00 00       	push   $0x28f
f01010b5:	68 5b 56 10 f0       	push   $0xf010565b
f01010ba:	e8 ea ef ff ff       	call   f01000a9 <_panic>
	assert(nfree_extmem > 0);
f01010bf:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01010c3:	7f 43                	jg     f0101108 <check_page_free_list+0x270>
f01010c5:	68 35 57 10 f0       	push   $0xf0105735
f01010ca:	68 7a 56 10 f0       	push   $0xf010567a
f01010cf:	68 90 02 00 00       	push   $0x290
f01010d4:	68 5b 56 10 f0       	push   $0xf010565b
f01010d9:	e8 cb ef ff ff       	call   f01000a9 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01010de:	8b 1d c0 5b 19 f0    	mov    0xf0195bc0,%ebx
f01010e4:	85 db                	test   %ebx,%ebx
f01010e6:	0f 85 d9 fd ff ff    	jne    f0100ec5 <check_page_free_list+0x2d>
f01010ec:	e9 bd fd ff ff       	jmp    f0100eae <check_page_free_list+0x16>
f01010f1:	83 3d c0 5b 19 f0 00 	cmpl   $0x0,0xf0195bc0
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
f0101113:	3b 05 84 78 19 f0    	cmp    0xf0197884,%eax
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
f0101121:	68 d4 50 10 f0       	push   $0xf01050d4
f0101126:	6a 4f                	push   $0x4f
f0101128:	68 4d 56 10 f0       	push   $0xf010564d
f010112d:	e8 77 ef ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f0101132:	8b 15 8c 78 19 f0    	mov    0xf019788c,%edx
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
f0101152:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0101157:	e8 3b fa ff ff       	call   f0100b97 <_paddr>
f010115c:	c1 e8 0c             	shr    $0xc,%eax
f010115f:	8b 35 c0 5b 19 f0    	mov    0xf0195bc0,%esi
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
f0101186:	03 1d 8c 78 19 f0    	add    0xf019788c,%ebx
f010118c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
		pages[i].pp_link = page_free_list;
f0101192:	89 33                	mov    %esi,(%ebx)
		page_free_list = &pages[i];
f0101194:	89 ce                	mov    %ecx,%esi
f0101196:	03 35 8c 78 19 f0    	add    0xf019788c,%esi
f010119c:	b9 01 00 00 00       	mov    $0x1,%ecx
	// free pages!
	size_t i;
	uint32_t lim_inf_IO = PGNUM(IOPHYSMEM);//==npages_basemem
	//uint32_t lim_sup_IO = PGNUM(EXTPHYSMEM); //no hace falta por lim_sup_kernmem > lim_sup_IO
	uint32_t lim_sup_kernmem = PGNUM(PADDR(boot_alloc(0)));
	for (i = 1; i < npages; i++) {//la 0 no se agrega tampoco
f01011a1:	83 c2 01             	add    $0x1,%edx
f01011a4:	3b 15 84 78 19 f0    	cmp    0xf0197884,%edx
f01011aa:	72 c5                	jb     f0101171 <page_init+0x35>
f01011ac:	84 c9                	test   %cl,%cl
f01011ae:	74 06                	je     f01011b6 <page_init+0x7a>
f01011b0:	89 35 c0 5b 19 f0    	mov    %esi,0xf0195bc0
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
f01011c1:	8b 1d c0 5b 19 f0    	mov    0xf0195bc0,%ebx
f01011c7:	85 db                	test   %ebx,%ebx
f01011c9:	74 2d                	je     f01011f8 <page_alloc+0x3e>
	struct PageInfo* pag = page_free_list;
	page_free_list = page_free_list->pp_link;
f01011cb:	8b 03                	mov    (%ebx),%eax
f01011cd:	a3 c0 5b 19 f0       	mov    %eax,0xf0195bc0
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
f01011f0:	e8 94 32 00 00       	call   f0104489 <memset>
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
f0101212:	68 46 57 10 f0       	push   $0xf0105746
f0101217:	68 42 01 00 00       	push   $0x142
f010121c:	68 5b 56 10 f0       	push   $0xf010565b
f0101221:	e8 83 ee ff ff       	call   f01000a9 <_panic>
	if (pp->pp_link) panic("page has non-NULL pp_link (already freed?)\n");
f0101226:	83 38 00             	cmpl   $0x0,(%eax)
f0101229:	74 17                	je     f0101242 <page_free+0x43>
f010122b:	83 ec 04             	sub    $0x4,%esp
f010122e:	68 f4 50 10 f0       	push   $0xf01050f4
f0101233:	68 43 01 00 00       	push   $0x143
f0101238:	68 5b 56 10 f0       	push   $0xf010565b
f010123d:	e8 67 ee ff ff       	call   f01000a9 <_panic>
	//pp_ref=0,pp_link=NULL
	pp->pp_link=page_free_list;
f0101242:	8b 15 c0 5b 19 f0    	mov    0xf0195bc0,%edx
f0101248:	89 10                	mov    %edx,(%eax)
	page_free_list=pp;
f010124a:	a3 c0 5b 19 f0       	mov    %eax,0xf0195bc0
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
f010125a:	83 3d 8c 78 19 f0 00 	cmpl   $0x0,0xf019788c
f0101261:	75 17                	jne    f010127a <check_page_alloc+0x29>
		panic("'pages' is a null pointer!");
f0101263:	83 ec 04             	sub    $0x4,%esp
f0101266:	68 5a 57 10 f0       	push   $0xf010575a
f010126b:	68 a1 02 00 00       	push   $0x2a1
f0101270:	68 5b 56 10 f0       	push   $0xf010565b
f0101275:	e8 2f ee ff ff       	call   f01000a9 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010127a:	a1 c0 5b 19 f0       	mov    0xf0195bc0,%eax
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
f01012a2:	68 75 57 10 f0       	push   $0xf0105775
f01012a7:	68 7a 56 10 f0       	push   $0xf010567a
f01012ac:	68 a9 02 00 00       	push   $0x2a9
f01012b1:	68 5b 56 10 f0       	push   $0xf010565b
f01012b6:	e8 ee ed ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01012bb:	83 ec 0c             	sub    $0xc,%esp
f01012be:	6a 00                	push   $0x0
f01012c0:	e8 f5 fe ff ff       	call   f01011ba <page_alloc>
f01012c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012c8:	83 c4 10             	add    $0x10,%esp
f01012cb:	85 c0                	test   %eax,%eax
f01012cd:	75 19                	jne    f01012e8 <check_page_alloc+0x97>
f01012cf:	68 8b 57 10 f0       	push   $0xf010578b
f01012d4:	68 7a 56 10 f0       	push   $0xf010567a
f01012d9:	68 aa 02 00 00       	push   $0x2aa
f01012de:	68 5b 56 10 f0       	push   $0xf010565b
f01012e3:	e8 c1 ed ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01012e8:	83 ec 0c             	sub    $0xc,%esp
f01012eb:	6a 00                	push   $0x0
f01012ed:	e8 c8 fe ff ff       	call   f01011ba <page_alloc>
f01012f2:	89 c3                	mov    %eax,%ebx
f01012f4:	83 c4 10             	add    $0x10,%esp
f01012f7:	85 c0                	test   %eax,%eax
f01012f9:	75 19                	jne    f0101314 <check_page_alloc+0xc3>
f01012fb:	68 a1 57 10 f0       	push   $0xf01057a1
f0101300:	68 7a 56 10 f0       	push   $0xf010567a
f0101305:	68 ab 02 00 00       	push   $0x2ab
f010130a:	68 5b 56 10 f0       	push   $0xf010565b
f010130f:	e8 95 ed ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101314:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0101317:	75 19                	jne    f0101332 <check_page_alloc+0xe1>
f0101319:	68 b7 57 10 f0       	push   $0xf01057b7
f010131e:	68 7a 56 10 f0       	push   $0xf010567a
f0101323:	68 ae 02 00 00       	push   $0x2ae
f0101328:	68 5b 56 10 f0       	push   $0xf010565b
f010132d:	e8 77 ed ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101332:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f0101335:	74 04                	je     f010133b <check_page_alloc+0xea>
f0101337:	39 c7                	cmp    %eax,%edi
f0101339:	75 19                	jne    f0101354 <check_page_alloc+0x103>
f010133b:	68 20 51 10 f0       	push   $0xf0105120
f0101340:	68 7a 56 10 f0       	push   $0xf010567a
f0101345:	68 af 02 00 00       	push   $0x2af
f010134a:	68 5b 56 10 f0       	push   $0xf010565b
f010134f:	e8 55 ed ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101354:	89 f8                	mov    %edi,%eax
f0101356:	e8 e2 f6 ff ff       	call   f0100a3d <page2pa>
f010135b:	8b 0d 84 78 19 f0    	mov    0xf0197884,%ecx
f0101361:	c1 e1 0c             	shl    $0xc,%ecx
f0101364:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101367:	39 c8                	cmp    %ecx,%eax
f0101369:	72 19                	jb     f0101384 <check_page_alloc+0x133>
f010136b:	68 c9 57 10 f0       	push   $0xf01057c9
f0101370:	68 7a 56 10 f0       	push   $0xf010567a
f0101375:	68 b0 02 00 00       	push   $0x2b0
f010137a:	68 5b 56 10 f0       	push   $0xf010565b
f010137f:	e8 25 ed ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101384:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101387:	e8 b1 f6 ff ff       	call   f0100a3d <page2pa>
f010138c:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f010138f:	77 19                	ja     f01013aa <check_page_alloc+0x159>
f0101391:	68 e6 57 10 f0       	push   $0xf01057e6
f0101396:	68 7a 56 10 f0       	push   $0xf010567a
f010139b:	68 b1 02 00 00       	push   $0x2b1
f01013a0:	68 5b 56 10 f0       	push   $0xf010565b
f01013a5:	e8 ff ec ff ff       	call   f01000a9 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01013aa:	89 d8                	mov    %ebx,%eax
f01013ac:	e8 8c f6 ff ff       	call   f0100a3d <page2pa>
f01013b1:	39 45 e0             	cmp    %eax,-0x20(%ebp)
f01013b4:	77 19                	ja     f01013cf <check_page_alloc+0x17e>
f01013b6:	68 03 58 10 f0       	push   $0xf0105803
f01013bb:	68 7a 56 10 f0       	push   $0xf010567a
f01013c0:	68 b2 02 00 00       	push   $0x2b2
f01013c5:	68 5b 56 10 f0       	push   $0xf010565b
f01013ca:	e8 da ec ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01013cf:	a1 c0 5b 19 f0       	mov    0xf0195bc0,%eax
f01013d4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01013d7:	c7 05 c0 5b 19 f0 00 	movl   $0x0,0xf0195bc0
f01013de:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01013e1:	83 ec 0c             	sub    $0xc,%esp
f01013e4:	6a 00                	push   $0x0
f01013e6:	e8 cf fd ff ff       	call   f01011ba <page_alloc>
f01013eb:	83 c4 10             	add    $0x10,%esp
f01013ee:	85 c0                	test   %eax,%eax
f01013f0:	74 19                	je     f010140b <check_page_alloc+0x1ba>
f01013f2:	68 20 58 10 f0       	push   $0xf0105820
f01013f7:	68 7a 56 10 f0       	push   $0xf010567a
f01013fc:	68 b9 02 00 00       	push   $0x2b9
f0101401:	68 5b 56 10 f0       	push   $0xf010565b
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
f010143c:	68 75 57 10 f0       	push   $0xf0105775
f0101441:	68 7a 56 10 f0       	push   $0xf010567a
f0101446:	68 c0 02 00 00       	push   $0x2c0
f010144b:	68 5b 56 10 f0       	push   $0xf010565b
f0101450:	e8 54 ec ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f0101455:	83 ec 0c             	sub    $0xc,%esp
f0101458:	6a 00                	push   $0x0
f010145a:	e8 5b fd ff ff       	call   f01011ba <page_alloc>
f010145f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101462:	83 c4 10             	add    $0x10,%esp
f0101465:	85 c0                	test   %eax,%eax
f0101467:	75 19                	jne    f0101482 <check_page_alloc+0x231>
f0101469:	68 8b 57 10 f0       	push   $0xf010578b
f010146e:	68 7a 56 10 f0       	push   $0xf010567a
f0101473:	68 c1 02 00 00       	push   $0x2c1
f0101478:	68 5b 56 10 f0       	push   $0xf010565b
f010147d:	e8 27 ec ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f0101482:	83 ec 0c             	sub    $0xc,%esp
f0101485:	6a 00                	push   $0x0
f0101487:	e8 2e fd ff ff       	call   f01011ba <page_alloc>
f010148c:	89 c7                	mov    %eax,%edi
f010148e:	83 c4 10             	add    $0x10,%esp
f0101491:	85 c0                	test   %eax,%eax
f0101493:	75 19                	jne    f01014ae <check_page_alloc+0x25d>
f0101495:	68 a1 57 10 f0       	push   $0xf01057a1
f010149a:	68 7a 56 10 f0       	push   $0xf010567a
f010149f:	68 c2 02 00 00       	push   $0x2c2
f01014a4:	68 5b 56 10 f0       	push   $0xf010565b
f01014a9:	e8 fb eb ff ff       	call   f01000a9 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014ae:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01014b1:	75 19                	jne    f01014cc <check_page_alloc+0x27b>
f01014b3:	68 b7 57 10 f0       	push   $0xf01057b7
f01014b8:	68 7a 56 10 f0       	push   $0xf010567a
f01014bd:	68 c4 02 00 00       	push   $0x2c4
f01014c2:	68 5b 56 10 f0       	push   $0xf010565b
f01014c7:	e8 dd eb ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01014cc:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f01014cf:	74 04                	je     f01014d5 <check_page_alloc+0x284>
f01014d1:	39 c3                	cmp    %eax,%ebx
f01014d3:	75 19                	jne    f01014ee <check_page_alloc+0x29d>
f01014d5:	68 20 51 10 f0       	push   $0xf0105120
f01014da:	68 7a 56 10 f0       	push   $0xf010567a
f01014df:	68 c5 02 00 00       	push   $0x2c5
f01014e4:	68 5b 56 10 f0       	push   $0xf010565b
f01014e9:	e8 bb eb ff ff       	call   f01000a9 <_panic>
	assert(!page_alloc(0));
f01014ee:	83 ec 0c             	sub    $0xc,%esp
f01014f1:	6a 00                	push   $0x0
f01014f3:	e8 c2 fc ff ff       	call   f01011ba <page_alloc>
f01014f8:	83 c4 10             	add    $0x10,%esp
f01014fb:	85 c0                	test   %eax,%eax
f01014fd:	74 19                	je     f0101518 <check_page_alloc+0x2c7>
f01014ff:	68 20 58 10 f0       	push   $0xf0105820
f0101504:	68 7a 56 10 f0       	push   $0xf010567a
f0101509:	68 c6 02 00 00       	push   $0x2c6
f010150e:	68 5b 56 10 f0       	push   $0xf010565b
f0101513:	e8 91 eb ff ff       	call   f01000a9 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101518:	89 d8                	mov    %ebx,%eax
f010151a:	e8 ea f5 ff ff       	call   f0100b09 <page2kva>
f010151f:	83 ec 04             	sub    $0x4,%esp
f0101522:	68 00 10 00 00       	push   $0x1000
f0101527:	6a 01                	push   $0x1
f0101529:	50                   	push   %eax
f010152a:	e8 5a 2f 00 00       	call   f0104489 <memset>
	page_free(pp0);
f010152f:	89 1c 24             	mov    %ebx,(%esp)
f0101532:	e8 c8 fc ff ff       	call   f01011ff <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101537:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010153e:	e8 77 fc ff ff       	call   f01011ba <page_alloc>
f0101543:	83 c4 10             	add    $0x10,%esp
f0101546:	85 c0                	test   %eax,%eax
f0101548:	75 19                	jne    f0101563 <check_page_alloc+0x312>
f010154a:	68 2f 58 10 f0       	push   $0xf010582f
f010154f:	68 7a 56 10 f0       	push   $0xf010567a
f0101554:	68 cb 02 00 00       	push   $0x2cb
f0101559:	68 5b 56 10 f0       	push   $0xf010565b
f010155e:	e8 46 eb ff ff       	call   f01000a9 <_panic>
	assert(pp && pp0 == pp);
f0101563:	39 c3                	cmp    %eax,%ebx
f0101565:	74 19                	je     f0101580 <check_page_alloc+0x32f>
f0101567:	68 4d 58 10 f0       	push   $0xf010584d
f010156c:	68 7a 56 10 f0       	push   $0xf010567a
f0101571:	68 cc 02 00 00       	push   $0x2cc
f0101576:	68 5b 56 10 f0       	push   $0xf010565b
f010157b:	e8 29 eb ff ff       	call   f01000a9 <_panic>
	c = page2kva(pp);
f0101580:	89 d8                	mov    %ebx,%eax
f0101582:	e8 82 f5 ff ff       	call   f0100b09 <page2kva>
f0101587:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010158d:	80 38 00             	cmpb   $0x0,(%eax)
f0101590:	74 19                	je     f01015ab <check_page_alloc+0x35a>
f0101592:	68 5d 58 10 f0       	push   $0xf010585d
f0101597:	68 7a 56 10 f0       	push   $0xf010567a
f010159c:	68 cf 02 00 00       	push   $0x2cf
f01015a1:	68 5b 56 10 f0       	push   $0xf010565b
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
f01015b5:	a3 c0 5b 19 f0       	mov    %eax,0xf0195bc0

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
f01015d6:	a1 c0 5b 19 f0       	mov    0xf0195bc0,%eax
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
f01015ed:	68 67 58 10 f0       	push   $0xf0105867
f01015f2:	68 7a 56 10 f0       	push   $0xf010567a
f01015f7:	68 dc 02 00 00       	push   $0x2dc
f01015fc:	68 5b 56 10 f0       	push   $0xf010565b
f0101601:	e8 a3 ea ff ff       	call   f01000a9 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101606:	83 ec 0c             	sub    $0xc,%esp
f0101609:	68 40 51 10 f0       	push   $0xf0105140
f010160e:	e8 6f 1a 00 00       	call   f0103082 <cprintf>
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
f010166b:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
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
f01016c0:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
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
f01016fb:	68 72 58 10 f0       	push   $0xf0105872
f0101700:	68 7a 56 10 f0       	push   $0xf010567a
f0101705:	68 8a 01 00 00       	push   $0x18a
f010170a:	68 5b 56 10 f0       	push   $0xf010565b
f010170f:	e8 95 e9 ff ff       	call   f01000a9 <_panic>
f0101714:	89 cf                	mov    %ecx,%edi
	assert(pa % PGSIZE == 0);
f0101716:	a9 ff 0f 00 00       	test   $0xfff,%eax
f010171b:	74 19                	je     f0101736 <boot_map_region+0x52>
f010171d:	68 83 58 10 f0       	push   $0xf0105883
f0101722:	68 7a 56 10 f0       	push   $0xf010567a
f0101727:	68 8b 01 00 00       	push   $0x18b
f010172c:	68 5b 56 10 f0       	push   $0xf010565b
f0101731:	e8 73 e9 ff ff       	call   f01000a9 <_panic>
	assert(size % PGSIZE == 0);	
f0101736:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f010173c:	74 3d                	je     f010177b <boot_map_region+0x97>
f010173e:	68 94 58 10 f0       	push   $0xf0105894
f0101743:	68 7a 56 10 f0       	push   $0xf010567a
f0101748:	68 8c 01 00 00       	push   $0x18c
f010174d:	68 5b 56 10 f0       	push   $0xf010565b
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
f01018b3:	68 75 57 10 f0       	push   $0xf0105775
f01018b8:	68 7a 56 10 f0       	push   $0xf010567a
f01018bd:	68 46 03 00 00       	push   $0x346
f01018c2:	68 5b 56 10 f0       	push   $0xf010565b
f01018c7:	e8 dd e7 ff ff       	call   f01000a9 <_panic>
	assert((pp1 = page_alloc(0)));
f01018cc:	83 ec 0c             	sub    $0xc,%esp
f01018cf:	6a 00                	push   $0x0
f01018d1:	e8 e4 f8 ff ff       	call   f01011ba <page_alloc>
f01018d6:	89 c6                	mov    %eax,%esi
f01018d8:	83 c4 10             	add    $0x10,%esp
f01018db:	85 c0                	test   %eax,%eax
f01018dd:	75 19                	jne    f01018f8 <check_page+0x5f>
f01018df:	68 8b 57 10 f0       	push   $0xf010578b
f01018e4:	68 7a 56 10 f0       	push   $0xf010567a
f01018e9:	68 47 03 00 00       	push   $0x347
f01018ee:	68 5b 56 10 f0       	push   $0xf010565b
f01018f3:	e8 b1 e7 ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01018f8:	83 ec 0c             	sub    $0xc,%esp
f01018fb:	6a 00                	push   $0x0
f01018fd:	e8 b8 f8 ff ff       	call   f01011ba <page_alloc>
f0101902:	89 c3                	mov    %eax,%ebx
f0101904:	83 c4 10             	add    $0x10,%esp
f0101907:	85 c0                	test   %eax,%eax
f0101909:	75 19                	jne    f0101924 <check_page+0x8b>
f010190b:	68 a1 57 10 f0       	push   $0xf01057a1
f0101910:	68 7a 56 10 f0       	push   $0xf010567a
f0101915:	68 48 03 00 00       	push   $0x348
f010191a:	68 5b 56 10 f0       	push   $0xf010565b
f010191f:	e8 85 e7 ff ff       	call   f01000a9 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101924:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101927:	75 19                	jne    f0101942 <check_page+0xa9>
f0101929:	68 b7 57 10 f0       	push   $0xf01057b7
f010192e:	68 7a 56 10 f0       	push   $0xf010567a
f0101933:	68 4b 03 00 00       	push   $0x34b
f0101938:	68 5b 56 10 f0       	push   $0xf010565b
f010193d:	e8 67 e7 ff ff       	call   f01000a9 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101942:	39 c6                	cmp    %eax,%esi
f0101944:	74 05                	je     f010194b <check_page+0xb2>
f0101946:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101949:	75 19                	jne    f0101964 <check_page+0xcb>
f010194b:	68 20 51 10 f0       	push   $0xf0105120
f0101950:	68 7a 56 10 f0       	push   $0xf010567a
f0101955:	68 4c 03 00 00       	push   $0x34c
f010195a:	68 5b 56 10 f0       	push   $0xf010565b
f010195f:	e8 45 e7 ff ff       	call   f01000a9 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101964:	a1 c0 5b 19 f0       	mov    0xf0195bc0,%eax
f0101969:	89 45 cc             	mov    %eax,-0x34(%ebp)
	page_free_list = 0;
f010196c:	c7 05 c0 5b 19 f0 00 	movl   $0x0,0xf0195bc0
f0101973:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101976:	83 ec 0c             	sub    $0xc,%esp
f0101979:	6a 00                	push   $0x0
f010197b:	e8 3a f8 ff ff       	call   f01011ba <page_alloc>
f0101980:	83 c4 10             	add    $0x10,%esp
f0101983:	85 c0                	test   %eax,%eax
f0101985:	74 19                	je     f01019a0 <check_page+0x107>
f0101987:	68 20 58 10 f0       	push   $0xf0105820
f010198c:	68 7a 56 10 f0       	push   $0xf010567a
f0101991:	68 53 03 00 00       	push   $0x353
f0101996:	68 5b 56 10 f0       	push   $0xf010565b
f010199b:	e8 09 e7 ff ff       	call   f01000a9 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01019a0:	83 ec 04             	sub    $0x4,%esp
f01019a3:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01019a6:	50                   	push   %eax
f01019a7:	6a 00                	push   $0x0
f01019a9:	ff 35 88 78 19 f0    	pushl  0xf0197888
f01019af:	e8 e9 fd ff ff       	call   f010179d <page_lookup>
f01019b4:	83 c4 10             	add    $0x10,%esp
f01019b7:	85 c0                	test   %eax,%eax
f01019b9:	74 19                	je     f01019d4 <check_page+0x13b>
f01019bb:	68 60 51 10 f0       	push   $0xf0105160
f01019c0:	68 7a 56 10 f0       	push   $0xf010567a
f01019c5:	68 56 03 00 00       	push   $0x356
f01019ca:	68 5b 56 10 f0       	push   $0xf010565b
f01019cf:	e8 d5 e6 ff ff       	call   f01000a9 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019d4:	6a 02                	push   $0x2
f01019d6:	6a 00                	push   $0x0
f01019d8:	56                   	push   %esi
f01019d9:	ff 35 88 78 19 f0    	pushl  0xf0197888
f01019df:	e8 54 fe ff ff       	call   f0101838 <page_insert>
f01019e4:	83 c4 10             	add    $0x10,%esp
f01019e7:	85 c0                	test   %eax,%eax
f01019e9:	78 19                	js     f0101a04 <check_page+0x16b>
f01019eb:	68 98 51 10 f0       	push   $0xf0105198
f01019f0:	68 7a 56 10 f0       	push   $0xf010567a
f01019f5:	68 59 03 00 00       	push   $0x359
f01019fa:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101a14:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101a1a:	e8 19 fe ff ff       	call   f0101838 <page_insert>
f0101a1f:	83 c4 20             	add    $0x20,%esp
f0101a22:	85 c0                	test   %eax,%eax
f0101a24:	74 19                	je     f0101a3f <check_page+0x1a6>
f0101a26:	68 c8 51 10 f0       	push   $0xf01051c8
f0101a2b:	68 7a 56 10 f0       	push   $0xf010567a
f0101a30:	68 5d 03 00 00       	push   $0x35d
f0101a35:	68 5b 56 10 f0       	push   $0xf010565b
f0101a3a:	e8 6a e6 ff ff       	call   f01000a9 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a3f:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f0101a45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a48:	e8 f0 ef ff ff       	call   f0100a3d <page2pa>
f0101a4d:	8b 17                	mov    (%edi),%edx
f0101a4f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a55:	39 c2                	cmp    %eax,%edx
f0101a57:	74 19                	je     f0101a72 <check_page+0x1d9>
f0101a59:	68 f8 51 10 f0       	push   $0xf01051f8
f0101a5e:	68 7a 56 10 f0       	push   $0xf010567a
f0101a63:	68 5e 03 00 00       	push   $0x35e
f0101a68:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101a8d:	68 20 52 10 f0       	push   $0xf0105220
f0101a92:	68 7a 56 10 f0       	push   $0xf010567a
f0101a97:	68 5f 03 00 00       	push   $0x35f
f0101a9c:	68 5b 56 10 f0       	push   $0xf010565b
f0101aa1:	e8 03 e6 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0101aa6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aab:	74 19                	je     f0101ac6 <check_page+0x22d>
f0101aad:	68 a7 58 10 f0       	push   $0xf01058a7
f0101ab2:	68 7a 56 10 f0       	push   $0xf010567a
f0101ab7:	68 60 03 00 00       	push   $0x360
f0101abc:	68 5b 56 10 f0       	push   $0xf010565b
f0101ac1:	e8 e3 e5 ff ff       	call   f01000a9 <_panic>
	assert(pp0->pp_ref == 1);
f0101ac6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ace:	74 19                	je     f0101ae9 <check_page+0x250>
f0101ad0:	68 b8 58 10 f0       	push   $0xf01058b8
f0101ad5:	68 7a 56 10 f0       	push   $0xf010567a
f0101ada:	68 61 03 00 00       	push   $0x361
f0101adf:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101afe:	68 50 52 10 f0       	push   $0xf0105250
f0101b03:	68 7a 56 10 f0       	push   $0xf010567a
f0101b08:	68 63 03 00 00       	push   $0x363
f0101b0d:	68 5b 56 10 f0       	push   $0xf010565b
f0101b12:	e8 92 e5 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b17:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b1c:	a1 88 78 19 f0       	mov    0xf0197888,%eax
f0101b21:	e8 01 f0 ff ff       	call   f0100b27 <check_va2pa>
f0101b26:	89 c7                	mov    %eax,%edi
f0101b28:	89 d8                	mov    %ebx,%eax
f0101b2a:	e8 0e ef ff ff       	call   f0100a3d <page2pa>
f0101b2f:	39 c7                	cmp    %eax,%edi
f0101b31:	74 19                	je     f0101b4c <check_page+0x2b3>
f0101b33:	68 8c 52 10 f0       	push   $0xf010528c
f0101b38:	68 7a 56 10 f0       	push   $0xf010567a
f0101b3d:	68 64 03 00 00       	push   $0x364
f0101b42:	68 5b 56 10 f0       	push   $0xf010565b
f0101b47:	e8 5d e5 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101b4c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b51:	74 19                	je     f0101b6c <check_page+0x2d3>
f0101b53:	68 c9 58 10 f0       	push   $0xf01058c9
f0101b58:	68 7a 56 10 f0       	push   $0xf010567a
f0101b5d:	68 65 03 00 00       	push   $0x365
f0101b62:	68 5b 56 10 f0       	push   $0xf010565b
f0101b67:	e8 3d e5 ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b6c:	83 ec 0c             	sub    $0xc,%esp
f0101b6f:	6a 00                	push   $0x0
f0101b71:	e8 44 f6 ff ff       	call   f01011ba <page_alloc>
f0101b76:	83 c4 10             	add    $0x10,%esp
f0101b79:	85 c0                	test   %eax,%eax
f0101b7b:	74 19                	je     f0101b96 <check_page+0x2fd>
f0101b7d:	68 20 58 10 f0       	push   $0xf0105820
f0101b82:	68 7a 56 10 f0       	push   $0xf010567a
f0101b87:	68 68 03 00 00       	push   $0x368
f0101b8c:	68 5b 56 10 f0       	push   $0xf010565b
f0101b91:	e8 13 e5 ff ff       	call   f01000a9 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b96:	6a 02                	push   $0x2
f0101b98:	68 00 10 00 00       	push   $0x1000
f0101b9d:	53                   	push   %ebx
f0101b9e:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101ba4:	e8 8f fc ff ff       	call   f0101838 <page_insert>
f0101ba9:	83 c4 10             	add    $0x10,%esp
f0101bac:	85 c0                	test   %eax,%eax
f0101bae:	74 19                	je     f0101bc9 <check_page+0x330>
f0101bb0:	68 50 52 10 f0       	push   $0xf0105250
f0101bb5:	68 7a 56 10 f0       	push   $0xf010567a
f0101bba:	68 6b 03 00 00       	push   $0x36b
f0101bbf:	68 5b 56 10 f0       	push   $0xf010565b
f0101bc4:	e8 e0 e4 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bce:	a1 88 78 19 f0       	mov    0xf0197888,%eax
f0101bd3:	e8 4f ef ff ff       	call   f0100b27 <check_va2pa>
f0101bd8:	89 c7                	mov    %eax,%edi
f0101bda:	89 d8                	mov    %ebx,%eax
f0101bdc:	e8 5c ee ff ff       	call   f0100a3d <page2pa>
f0101be1:	39 c7                	cmp    %eax,%edi
f0101be3:	74 19                	je     f0101bfe <check_page+0x365>
f0101be5:	68 8c 52 10 f0       	push   $0xf010528c
f0101bea:	68 7a 56 10 f0       	push   $0xf010567a
f0101bef:	68 6c 03 00 00       	push   $0x36c
f0101bf4:	68 5b 56 10 f0       	push   $0xf010565b
f0101bf9:	e8 ab e4 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101bfe:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c03:	74 19                	je     f0101c1e <check_page+0x385>
f0101c05:	68 c9 58 10 f0       	push   $0xf01058c9
f0101c0a:	68 7a 56 10 f0       	push   $0xf010567a
f0101c0f:	68 6d 03 00 00       	push   $0x36d
f0101c14:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101c2f:	68 20 58 10 f0       	push   $0xf0105820
f0101c34:	68 7a 56 10 f0       	push   $0xf010567a
f0101c39:	68 71 03 00 00       	push   $0x371
f0101c3e:	68 5b 56 10 f0       	push   $0xf010565b
f0101c43:	e8 61 e4 ff ff       	call   f01000a9 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c48:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f0101c4e:	8b 0f                	mov    (%edi),%ecx
f0101c50:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101c56:	ba 74 03 00 00       	mov    $0x374,%edx
f0101c5b:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
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
f0101c85:	68 bc 52 10 f0       	push   $0xf01052bc
f0101c8a:	68 7a 56 10 f0       	push   $0xf010567a
f0101c8f:	68 75 03 00 00       	push   $0x375
f0101c94:	68 5b 56 10 f0       	push   $0xf010565b
f0101c99:	e8 0b e4 ff ff       	call   f01000a9 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c9e:	6a 06                	push   $0x6
f0101ca0:	68 00 10 00 00       	push   $0x1000
f0101ca5:	53                   	push   %ebx
f0101ca6:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101cac:	e8 87 fb ff ff       	call   f0101838 <page_insert>
f0101cb1:	83 c4 10             	add    $0x10,%esp
f0101cb4:	85 c0                	test   %eax,%eax
f0101cb6:	74 19                	je     f0101cd1 <check_page+0x438>
f0101cb8:	68 fc 52 10 f0       	push   $0xf01052fc
f0101cbd:	68 7a 56 10 f0       	push   $0xf010567a
f0101cc2:	68 78 03 00 00       	push   $0x378
f0101cc7:	68 5b 56 10 f0       	push   $0xf010565b
f0101ccc:	e8 d8 e3 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cd1:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f0101cd7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cdc:	89 f8                	mov    %edi,%eax
f0101cde:	e8 44 ee ff ff       	call   f0100b27 <check_va2pa>
f0101ce3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ce6:	89 d8                	mov    %ebx,%eax
f0101ce8:	e8 50 ed ff ff       	call   f0100a3d <page2pa>
f0101ced:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101cf0:	74 19                	je     f0101d0b <check_page+0x472>
f0101cf2:	68 8c 52 10 f0       	push   $0xf010528c
f0101cf7:	68 7a 56 10 f0       	push   $0xf010567a
f0101cfc:	68 79 03 00 00       	push   $0x379
f0101d01:	68 5b 56 10 f0       	push   $0xf010565b
f0101d06:	e8 9e e3 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f0101d0b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d10:	74 19                	je     f0101d2b <check_page+0x492>
f0101d12:	68 c9 58 10 f0       	push   $0xf01058c9
f0101d17:	68 7a 56 10 f0       	push   $0xf010567a
f0101d1c:	68 7a 03 00 00       	push   $0x37a
f0101d21:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101d43:	68 3c 53 10 f0       	push   $0xf010533c
f0101d48:	68 7a 56 10 f0       	push   $0xf010567a
f0101d4d:	68 7b 03 00 00       	push   $0x37b
f0101d52:	68 5b 56 10 f0       	push   $0xf010565b
f0101d57:	e8 4d e3 ff ff       	call   f01000a9 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d5c:	a1 88 78 19 f0       	mov    0xf0197888,%eax
f0101d61:	f6 00 04             	testb  $0x4,(%eax)
f0101d64:	75 19                	jne    f0101d7f <check_page+0x4e6>
f0101d66:	68 da 58 10 f0       	push   $0xf01058da
f0101d6b:	68 7a 56 10 f0       	push   $0xf010567a
f0101d70:	68 7c 03 00 00       	push   $0x37c
f0101d75:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101d94:	68 50 52 10 f0       	push   $0xf0105250
f0101d99:	68 7a 56 10 f0       	push   $0xf010567a
f0101d9e:	68 7f 03 00 00       	push   $0x37f
f0101da3:	68 5b 56 10 f0       	push   $0xf010565b
f0101da8:	e8 fc e2 ff ff       	call   f01000a9 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101dad:	83 ec 04             	sub    $0x4,%esp
f0101db0:	6a 00                	push   $0x0
f0101db2:	68 00 10 00 00       	push   $0x1000
f0101db7:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101dbd:	e8 83 f8 ff ff       	call   f0101645 <pgdir_walk>
f0101dc2:	83 c4 10             	add    $0x10,%esp
f0101dc5:	f6 00 02             	testb  $0x2,(%eax)
f0101dc8:	75 19                	jne    f0101de3 <check_page+0x54a>
f0101dca:	68 70 53 10 f0       	push   $0xf0105370
f0101dcf:	68 7a 56 10 f0       	push   $0xf010567a
f0101dd4:	68 80 03 00 00       	push   $0x380
f0101dd9:	68 5b 56 10 f0       	push   $0xf010565b
f0101dde:	e8 c6 e2 ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101de3:	83 ec 04             	sub    $0x4,%esp
f0101de6:	6a 00                	push   $0x0
f0101de8:	68 00 10 00 00       	push   $0x1000
f0101ded:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101df3:	e8 4d f8 ff ff       	call   f0101645 <pgdir_walk>
f0101df8:	83 c4 10             	add    $0x10,%esp
f0101dfb:	f6 00 04             	testb  $0x4,(%eax)
f0101dfe:	74 19                	je     f0101e19 <check_page+0x580>
f0101e00:	68 a4 53 10 f0       	push   $0xf01053a4
f0101e05:	68 7a 56 10 f0       	push   $0xf010567a
f0101e0a:	68 81 03 00 00       	push   $0x381
f0101e0f:	68 5b 56 10 f0       	push   $0xf010565b
f0101e14:	e8 90 e2 ff ff       	call   f01000a9 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e19:	6a 02                	push   $0x2
f0101e1b:	68 00 00 40 00       	push   $0x400000
f0101e20:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101e23:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101e29:	e8 0a fa ff ff       	call   f0101838 <page_insert>
f0101e2e:	83 c4 10             	add    $0x10,%esp
f0101e31:	85 c0                	test   %eax,%eax
f0101e33:	78 19                	js     f0101e4e <check_page+0x5b5>
f0101e35:	68 dc 53 10 f0       	push   $0xf01053dc
f0101e3a:	68 7a 56 10 f0       	push   $0xf010567a
f0101e3f:	68 84 03 00 00       	push   $0x384
f0101e44:	68 5b 56 10 f0       	push   $0xf010565b
f0101e49:	e8 5b e2 ff ff       	call   f01000a9 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101e4e:	6a 02                	push   $0x2
f0101e50:	68 00 10 00 00       	push   $0x1000
f0101e55:	56                   	push   %esi
f0101e56:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101e5c:	e8 d7 f9 ff ff       	call   f0101838 <page_insert>
f0101e61:	83 c4 10             	add    $0x10,%esp
f0101e64:	85 c0                	test   %eax,%eax
f0101e66:	74 19                	je     f0101e81 <check_page+0x5e8>
f0101e68:	68 14 54 10 f0       	push   $0xf0105414
f0101e6d:	68 7a 56 10 f0       	push   $0xf010567a
f0101e72:	68 87 03 00 00       	push   $0x387
f0101e77:	68 5b 56 10 f0       	push   $0xf010565b
f0101e7c:	e8 28 e2 ff ff       	call   f01000a9 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e81:	83 ec 04             	sub    $0x4,%esp
f0101e84:	6a 00                	push   $0x0
f0101e86:	68 00 10 00 00       	push   $0x1000
f0101e8b:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101e91:	e8 af f7 ff ff       	call   f0101645 <pgdir_walk>
f0101e96:	83 c4 10             	add    $0x10,%esp
f0101e99:	f6 00 04             	testb  $0x4,(%eax)
f0101e9c:	74 19                	je     f0101eb7 <check_page+0x61e>
f0101e9e:	68 a4 53 10 f0       	push   $0xf01053a4
f0101ea3:	68 7a 56 10 f0       	push   $0xf010567a
f0101ea8:	68 88 03 00 00       	push   $0x388
f0101ead:	68 5b 56 10 f0       	push   $0xf010565b
f0101eb2:	e8 f2 e1 ff ff       	call   f01000a9 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101eb7:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f0101ebd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ec2:	89 f8                	mov    %edi,%eax
f0101ec4:	e8 5e ec ff ff       	call   f0100b27 <check_va2pa>
f0101ec9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101ecc:	89 f0                	mov    %esi,%eax
f0101ece:	e8 6a eb ff ff       	call   f0100a3d <page2pa>
f0101ed3:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101ed6:	74 19                	je     f0101ef1 <check_page+0x658>
f0101ed8:	68 50 54 10 f0       	push   $0xf0105450
f0101edd:	68 7a 56 10 f0       	push   $0xf010567a
f0101ee2:	68 8b 03 00 00       	push   $0x38b
f0101ee7:	68 5b 56 10 f0       	push   $0xf010565b
f0101eec:	e8 b8 e1 ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ef1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ef6:	89 f8                	mov    %edi,%eax
f0101ef8:	e8 2a ec ff ff       	call   f0100b27 <check_va2pa>
f0101efd:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f00:	74 19                	je     f0101f1b <check_page+0x682>
f0101f02:	68 7c 54 10 f0       	push   $0xf010547c
f0101f07:	68 7a 56 10 f0       	push   $0xf010567a
f0101f0c:	68 8c 03 00 00       	push   $0x38c
f0101f11:	68 5b 56 10 f0       	push   $0xf010565b
f0101f16:	e8 8e e1 ff ff       	call   f01000a9 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101f1b:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101f20:	74 19                	je     f0101f3b <check_page+0x6a2>
f0101f22:	68 f0 58 10 f0       	push   $0xf01058f0
f0101f27:	68 7a 56 10 f0       	push   $0xf010567a
f0101f2c:	68 8e 03 00 00       	push   $0x38e
f0101f31:	68 5b 56 10 f0       	push   $0xf010565b
f0101f36:	e8 6e e1 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f0101f3b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101f40:	74 19                	je     f0101f5b <check_page+0x6c2>
f0101f42:	68 01 59 10 f0       	push   $0xf0105901
f0101f47:	68 7a 56 10 f0       	push   $0xf010567a
f0101f4c:	68 8f 03 00 00       	push   $0x38f
f0101f51:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101f70:	68 ac 54 10 f0       	push   $0xf01054ac
f0101f75:	68 7a 56 10 f0       	push   $0xf010567a
f0101f7a:	68 92 03 00 00       	push   $0x392
f0101f7f:	68 5b 56 10 f0       	push   $0xf010565b
f0101f84:	e8 20 e1 ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101f89:	83 ec 08             	sub    $0x8,%esp
f0101f8c:	6a 00                	push   $0x0
f0101f8e:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0101f94:	e8 59 f8 ff ff       	call   f01017f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f99:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f0101f9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fa4:	89 f8                	mov    %edi,%eax
f0101fa6:	e8 7c eb ff ff       	call   f0100b27 <check_va2pa>
f0101fab:	83 c4 10             	add    $0x10,%esp
f0101fae:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101fb1:	74 19                	je     f0101fcc <check_page+0x733>
f0101fb3:	68 d0 54 10 f0       	push   $0xf01054d0
f0101fb8:	68 7a 56 10 f0       	push   $0xf010567a
f0101fbd:	68 96 03 00 00       	push   $0x396
f0101fc2:	68 5b 56 10 f0       	push   $0xf010565b
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
f0101fe7:	68 7c 54 10 f0       	push   $0xf010547c
f0101fec:	68 7a 56 10 f0       	push   $0xf010567a
f0101ff1:	68 97 03 00 00       	push   $0x397
f0101ff6:	68 5b 56 10 f0       	push   $0xf010565b
f0101ffb:	e8 a9 e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 1);
f0102000:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102005:	74 19                	je     f0102020 <check_page+0x787>
f0102007:	68 a7 58 10 f0       	push   $0xf01058a7
f010200c:	68 7a 56 10 f0       	push   $0xf010567a
f0102011:	68 98 03 00 00       	push   $0x398
f0102016:	68 5b 56 10 f0       	push   $0xf010565b
f010201b:	e8 89 e0 ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f0102020:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102025:	74 19                	je     f0102040 <check_page+0x7a7>
f0102027:	68 01 59 10 f0       	push   $0xf0105901
f010202c:	68 7a 56 10 f0       	push   $0xf010567a
f0102031:	68 99 03 00 00       	push   $0x399
f0102036:	68 5b 56 10 f0       	push   $0xf010565b
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
f0102055:	68 f4 54 10 f0       	push   $0xf01054f4
f010205a:	68 7a 56 10 f0       	push   $0xf010567a
f010205f:	68 9c 03 00 00       	push   $0x39c
f0102064:	68 5b 56 10 f0       	push   $0xf010565b
f0102069:	e8 3b e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref);
f010206e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102073:	75 19                	jne    f010208e <check_page+0x7f5>
f0102075:	68 12 59 10 f0       	push   $0xf0105912
f010207a:	68 7a 56 10 f0       	push   $0xf010567a
f010207f:	68 9d 03 00 00       	push   $0x39d
f0102084:	68 5b 56 10 f0       	push   $0xf010565b
f0102089:	e8 1b e0 ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_link == NULL);
f010208e:	83 3e 00             	cmpl   $0x0,(%esi)
f0102091:	74 19                	je     f01020ac <check_page+0x813>
f0102093:	68 1e 59 10 f0       	push   $0xf010591e
f0102098:	68 7a 56 10 f0       	push   $0xf010567a
f010209d:	68 9e 03 00 00       	push   $0x39e
f01020a2:	68 5b 56 10 f0       	push   $0xf010565b
f01020a7:	e8 fd df ff ff       	call   f01000a9 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020ac:	83 ec 08             	sub    $0x8,%esp
f01020af:	68 00 10 00 00       	push   $0x1000
f01020b4:	ff 35 88 78 19 f0    	pushl  0xf0197888
f01020ba:	e8 33 f7 ff ff       	call   f01017f2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020bf:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f01020c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01020ca:	89 f8                	mov    %edi,%eax
f01020cc:	e8 56 ea ff ff       	call   f0100b27 <check_va2pa>
f01020d1:	83 c4 10             	add    $0x10,%esp
f01020d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020d7:	74 19                	je     f01020f2 <check_page+0x859>
f01020d9:	68 d0 54 10 f0       	push   $0xf01054d0
f01020de:	68 7a 56 10 f0       	push   $0xf010567a
f01020e3:	68 a2 03 00 00       	push   $0x3a2
f01020e8:	68 5b 56 10 f0       	push   $0xf010565b
f01020ed:	e8 b7 df ff ff       	call   f01000a9 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020f2:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020f7:	89 f8                	mov    %edi,%eax
f01020f9:	e8 29 ea ff ff       	call   f0100b27 <check_va2pa>
f01020fe:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102101:	74 19                	je     f010211c <check_page+0x883>
f0102103:	68 2c 55 10 f0       	push   $0xf010552c
f0102108:	68 7a 56 10 f0       	push   $0xf010567a
f010210d:	68 a3 03 00 00       	push   $0x3a3
f0102112:	68 5b 56 10 f0       	push   $0xf010565b
f0102117:	e8 8d df ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f010211c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102121:	74 19                	je     f010213c <check_page+0x8a3>
f0102123:	68 33 59 10 f0       	push   $0xf0105933
f0102128:	68 7a 56 10 f0       	push   $0xf010567a
f010212d:	68 a4 03 00 00       	push   $0x3a4
f0102132:	68 5b 56 10 f0       	push   $0xf010565b
f0102137:	e8 6d df ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 0);
f010213c:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102141:	74 19                	je     f010215c <check_page+0x8c3>
f0102143:	68 01 59 10 f0       	push   $0xf0105901
f0102148:	68 7a 56 10 f0       	push   $0xf010567a
f010214d:	68 a5 03 00 00       	push   $0x3a5
f0102152:	68 5b 56 10 f0       	push   $0xf010565b
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
f0102171:	68 54 55 10 f0       	push   $0xf0105554
f0102176:	68 7a 56 10 f0       	push   $0xf010567a
f010217b:	68 a8 03 00 00       	push   $0x3a8
f0102180:	68 5b 56 10 f0       	push   $0xf010565b
f0102185:	e8 1f df ff ff       	call   f01000a9 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010218a:	83 ec 0c             	sub    $0xc,%esp
f010218d:	6a 00                	push   $0x0
f010218f:	e8 26 f0 ff ff       	call   f01011ba <page_alloc>
f0102194:	83 c4 10             	add    $0x10,%esp
f0102197:	85 c0                	test   %eax,%eax
f0102199:	74 19                	je     f01021b4 <check_page+0x91b>
f010219b:	68 20 58 10 f0       	push   $0xf0105820
f01021a0:	68 7a 56 10 f0       	push   $0xf010567a
f01021a5:	68 ab 03 00 00       	push   $0x3ab
f01021aa:	68 5b 56 10 f0       	push   $0xf010565b
f01021af:	e8 f5 de ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021b4:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f01021ba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021bd:	e8 7b e8 ff ff       	call   f0100a3d <page2pa>
f01021c2:	8b 17                	mov    (%edi),%edx
f01021c4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01021ca:	39 c2                	cmp    %eax,%edx
f01021cc:	74 19                	je     f01021e7 <check_page+0x94e>
f01021ce:	68 f8 51 10 f0       	push   $0xf01051f8
f01021d3:	68 7a 56 10 f0       	push   $0xf010567a
f01021d8:	68 ae 03 00 00       	push   $0x3ae
f01021dd:	68 5b 56 10 f0       	push   $0xf010565b
f01021e2:	e8 c2 de ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f01021e7:	c7 07 00 00 00 00    	movl   $0x0,(%edi)
	assert(pp0->pp_ref == 1);
f01021ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021f0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021f5:	74 19                	je     f0102210 <check_page+0x977>
f01021f7:	68 b8 58 10 f0       	push   $0xf01058b8
f01021fc:	68 7a 56 10 f0       	push   $0xf010567a
f0102201:	68 b0 03 00 00       	push   $0x3b0
f0102206:	68 5b 56 10 f0       	push   $0xf010565b
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
f010222c:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0102232:	e8 0e f4 ff ff       	call   f0101645 <pgdir_walk>
f0102237:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010223a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010223d:	8b 3d 88 78 19 f0    	mov    0xf0197888,%edi
f0102243:	8b 4f 04             	mov    0x4(%edi),%ecx
f0102246:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010224c:	ba b7 03 00 00       	mov    $0x3b7,%edx
f0102251:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0102256:	e8 82 e8 ff ff       	call   f0100add <_kaddr>
	assert(ptep == ptep1 + PTX(va));
f010225b:	83 c0 04             	add    $0x4,%eax
f010225e:	83 c4 10             	add    $0x10,%esp
f0102261:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102264:	74 19                	je     f010227f <check_page+0x9e6>
f0102266:	68 44 59 10 f0       	push   $0xf0105944
f010226b:	68 7a 56 10 f0       	push   $0xf010567a
f0102270:	68 b8 03 00 00       	push   $0x3b8
f0102275:	68 5b 56 10 f0       	push   $0xf010565b
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
f01022a4:	e8 e0 21 00 00       	call   f0104489 <memset>
	page_free(pp0);
f01022a9:	89 3c 24             	mov    %edi,(%esp)
f01022ac:	e8 4e ef ff ff       	call   f01011ff <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01022b1:	83 c4 0c             	add    $0xc,%esp
f01022b4:	6a 01                	push   $0x1
f01022b6:	6a 00                	push   $0x0
f01022b8:	ff 35 88 78 19 f0    	pushl  0xf0197888
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
f01022dc:	68 5c 59 10 f0       	push   $0xf010595c
f01022e1:	68 7a 56 10 f0       	push   $0xf010567a
f01022e6:	68 c2 03 00 00       	push   $0x3c2
f01022eb:	68 5b 56 10 f0       	push   $0xf010565b
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
f01022fc:	a1 88 78 19 f0       	mov    0xf0197888,%eax
f0102301:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102307:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010230a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102310:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102313:	89 0d c0 5b 19 f0    	mov    %ecx,0xf0195bc0

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
f0102332:	c7 04 24 73 59 10 f0 	movl   $0xf0105973,(%esp)
f0102339:	e8 44 0d 00 00       	call   f0103082 <cprintf>
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
f0102360:	68 75 57 10 f0       	push   $0xf0105775
f0102365:	68 7a 56 10 f0       	push   $0xf010567a
f010236a:	68 dd 03 00 00       	push   $0x3dd
f010236f:	68 5b 56 10 f0       	push   $0xf010565b
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
f010238e:	68 8b 57 10 f0       	push   $0xf010578b
f0102393:	68 7a 56 10 f0       	push   $0xf010567a
f0102398:	68 de 03 00 00       	push   $0x3de
f010239d:	68 5b 56 10 f0       	push   $0xf010565b
f01023a2:	e8 02 dd ff ff       	call   f01000a9 <_panic>
	assert((pp2 = page_alloc(0)));
f01023a7:	83 ec 0c             	sub    $0xc,%esp
f01023aa:	6a 00                	push   $0x0
f01023ac:	e8 09 ee ff ff       	call   f01011ba <page_alloc>
f01023b1:	89 c3                	mov    %eax,%ebx
f01023b3:	83 c4 10             	add    $0x10,%esp
f01023b6:	85 c0                	test   %eax,%eax
f01023b8:	75 19                	jne    f01023d3 <check_page_installed_pgdir+0x8a>
f01023ba:	68 a1 57 10 f0       	push   $0xf01057a1
f01023bf:	68 7a 56 10 f0       	push   $0xf010567a
f01023c4:	68 df 03 00 00       	push   $0x3df
f01023c9:	68 5b 56 10 f0       	push   $0xf010565b
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
f01023ee:	e8 96 20 00 00       	call   f0104489 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01023f3:	89 d8                	mov    %ebx,%eax
f01023f5:	e8 0f e7 ff ff       	call   f0100b09 <page2kva>
f01023fa:	83 c4 0c             	add    $0xc,%esp
f01023fd:	68 00 10 00 00       	push   $0x1000
f0102402:	6a 02                	push   $0x2
f0102404:	50                   	push   %eax
f0102405:	e8 7f 20 00 00       	call   f0104489 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010240a:	6a 02                	push   $0x2
f010240c:	68 00 10 00 00       	push   $0x1000
f0102411:	57                   	push   %edi
f0102412:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0102418:	e8 1b f4 ff ff       	call   f0101838 <page_insert>
	assert(pp1->pp_ref == 1);
f010241d:	83 c4 20             	add    $0x20,%esp
f0102420:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102425:	74 19                	je     f0102440 <check_page_installed_pgdir+0xf7>
f0102427:	68 a7 58 10 f0       	push   $0xf01058a7
f010242c:	68 7a 56 10 f0       	push   $0xf010567a
f0102431:	68 e4 03 00 00       	push   $0x3e4
f0102436:	68 5b 56 10 f0       	push   $0xf010565b
f010243b:	e8 69 dc ff ff       	call   f01000a9 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102440:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102447:	01 01 01 
f010244a:	74 19                	je     f0102465 <check_page_installed_pgdir+0x11c>
f010244c:	68 78 55 10 f0       	push   $0xf0105578
f0102451:	68 7a 56 10 f0       	push   $0xf010567a
f0102456:	68 e5 03 00 00       	push   $0x3e5
f010245b:	68 5b 56 10 f0       	push   $0xf010565b
f0102460:	e8 44 dc ff ff       	call   f01000a9 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102465:	6a 02                	push   $0x2
f0102467:	68 00 10 00 00       	push   $0x1000
f010246c:	53                   	push   %ebx
f010246d:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0102473:	e8 c0 f3 ff ff       	call   f0101838 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102478:	83 c4 10             	add    $0x10,%esp
f010247b:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102482:	02 02 02 
f0102485:	74 19                	je     f01024a0 <check_page_installed_pgdir+0x157>
f0102487:	68 9c 55 10 f0       	push   $0xf010559c
f010248c:	68 7a 56 10 f0       	push   $0xf010567a
f0102491:	68 e7 03 00 00       	push   $0x3e7
f0102496:	68 5b 56 10 f0       	push   $0xf010565b
f010249b:	e8 09 dc ff ff       	call   f01000a9 <_panic>
	assert(pp2->pp_ref == 1);
f01024a0:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024a5:	74 19                	je     f01024c0 <check_page_installed_pgdir+0x177>
f01024a7:	68 c9 58 10 f0       	push   $0xf01058c9
f01024ac:	68 7a 56 10 f0       	push   $0xf010567a
f01024b1:	68 e8 03 00 00       	push   $0x3e8
f01024b6:	68 5b 56 10 f0       	push   $0xf010565b
f01024bb:	e8 e9 db ff ff       	call   f01000a9 <_panic>
	assert(pp1->pp_ref == 0);
f01024c0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01024c5:	74 19                	je     f01024e0 <check_page_installed_pgdir+0x197>
f01024c7:	68 33 59 10 f0       	push   $0xf0105933
f01024cc:	68 7a 56 10 f0       	push   $0xf010567a
f01024d1:	68 e9 03 00 00       	push   $0x3e9
f01024d6:	68 5b 56 10 f0       	push   $0xf010565b
f01024db:	e8 c9 db ff ff       	call   f01000a9 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01024e0:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01024e7:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01024ea:	89 d8                	mov    %ebx,%eax
f01024ec:	e8 18 e6 ff ff       	call   f0100b09 <page2kva>
f01024f1:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01024f7:	74 19                	je     f0102512 <check_page_installed_pgdir+0x1c9>
f01024f9:	68 c0 55 10 f0       	push   $0xf01055c0
f01024fe:	68 7a 56 10 f0       	push   $0xf010567a
f0102503:	68 eb 03 00 00       	push   $0x3eb
f0102508:	68 5b 56 10 f0       	push   $0xf010565b
f010250d:	e8 97 db ff ff       	call   f01000a9 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102512:	83 ec 08             	sub    $0x8,%esp
f0102515:	68 00 10 00 00       	push   $0x1000
f010251a:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0102520:	e8 cd f2 ff ff       	call   f01017f2 <page_remove>
	assert(pp2->pp_ref == 0);
f0102525:	83 c4 10             	add    $0x10,%esp
f0102528:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010252d:	74 19                	je     f0102548 <check_page_installed_pgdir+0x1ff>
f010252f:	68 01 59 10 f0       	push   $0xf0105901
f0102534:	68 7a 56 10 f0       	push   $0xf010567a
f0102539:	68 ed 03 00 00       	push   $0x3ed
f010253e:	68 5b 56 10 f0       	push   $0xf010565b
f0102543:	e8 61 db ff ff       	call   f01000a9 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102548:	8b 1d 88 78 19 f0    	mov    0xf0197888,%ebx
f010254e:	89 f0                	mov    %esi,%eax
f0102550:	e8 e8 e4 ff ff       	call   f0100a3d <page2pa>
f0102555:	8b 13                	mov    (%ebx),%edx
f0102557:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010255d:	39 c2                	cmp    %eax,%edx
f010255f:	74 19                	je     f010257a <check_page_installed_pgdir+0x231>
f0102561:	68 f8 51 10 f0       	push   $0xf01051f8
f0102566:	68 7a 56 10 f0       	push   $0xf010567a
f010256b:	68 f0 03 00 00       	push   $0x3f0
f0102570:	68 5b 56 10 f0       	push   $0xf010565b
f0102575:	e8 2f db ff ff       	call   f01000a9 <_panic>
	kern_pgdir[0] = 0;
f010257a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	assert(pp0->pp_ref == 1);
f0102580:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102585:	74 19                	je     f01025a0 <check_page_installed_pgdir+0x257>
f0102587:	68 b8 58 10 f0       	push   $0xf01058b8
f010258c:	68 7a 56 10 f0       	push   $0xf010567a
f0102591:	68 f2 03 00 00       	push   $0x3f2
f0102596:	68 5b 56 10 f0       	push   $0xf010565b
f010259b:	e8 09 db ff ff       	call   f01000a9 <_panic>
	pp0->pp_ref = 0;
f01025a0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01025a6:	83 ec 0c             	sub    $0xc,%esp
f01025a9:	56                   	push   %esi
f01025aa:	e8 50 ec ff ff       	call   f01011ff <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01025af:	c7 04 24 ec 55 10 f0 	movl   $0xf01055ec,(%esp)
f01025b6:	e8 c7 0a 00 00       	call   f0103082 <cprintf>
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
f01025dc:	a3 88 78 19 f0       	mov    %eax,0xf0197888
	memset(kern_pgdir, 0, PGSIZE);
f01025e1:	83 ec 04             	sub    $0x4,%esp
f01025e4:	68 00 10 00 00       	push   $0x1000
f01025e9:	6a 00                	push   $0x0
f01025eb:	50                   	push   %eax
f01025ec:	e8 98 1e 00 00       	call   f0104489 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01025f1:	8b 1d 88 78 19 f0    	mov    0xf0197888,%ebx
f01025f7:	89 d9                	mov    %ebx,%ecx
f01025f9:	ba 93 00 00 00       	mov    $0x93,%edx
f01025fe:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0102603:	e8 8f e5 ff ff       	call   f0100b97 <_paddr>
f0102608:	83 c8 05             	or     $0x5,%eax
f010260b:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages=boot_alloc(npages //[page]
f0102611:	a1 84 78 19 f0       	mov    0xf0197884,%eax
f0102616:	c1 e0 03             	shl    $0x3,%eax
f0102619:	e8 9b e5 ff ff       	call   f0100bb9 <boot_alloc>
f010261e:	a3 8c 78 19 f0       	mov    %eax,0xf019788c
					 * sizeof(struct PageInfo));//[B/page]
	memset(pages,0,npages*sizeof(struct PageInfo));
f0102623:	83 c4 0c             	add    $0xc,%esp
f0102626:	8b 1d 84 78 19 f0    	mov    0xf0197884,%ebx
f010262c:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
f0102633:	52                   	push   %edx
f0102634:	6a 00                	push   $0x0
f0102636:	50                   	push   %eax
f0102637:	e8 4d 1e 00 00       	call   f0104489 <memset>
	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.

	envs = boot_alloc(NENV*sizeof(struct Env));
f010263c:	b8 00 80 01 00       	mov    $0x18000,%eax
f0102641:	e8 73 e5 ff ff       	call   f0100bb9 <boot_alloc>
f0102646:	a3 c8 5b 19 f0       	mov    %eax,0xf0195bc8
	memset(envs,0, NENV*sizeof(struct Env));
f010264b:	83 c4 0c             	add    $0xc,%esp
f010264e:	68 00 80 01 00       	push   $0x18000
f0102653:	6a 00                	push   $0x0
f0102655:	50                   	push   %eax
f0102656:	e8 2e 1e 00 00       	call   f0104489 <memset>
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
f0102674:	8b 0d 8c 78 19 f0    	mov    0xf019788c,%ecx
f010267a:	ba bd 00 00 00       	mov    $0xbd,%edx
f010267f:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f0102684:	e8 0e e5 ff ff       	call   f0100b97 <_paddr>
f0102689:	8b 1d 84 78 19 f0    	mov    0xf0197884,%ebx
f010268f:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
f0102696:	83 c4 08             	add    $0x8,%esp
f0102699:	6a 05                	push   $0x5
f010269b:	50                   	push   %eax
f010269c:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026a1:	a1 88 78 19 f0       	mov    0xf0197888,%eax
f01026a6:	e8 39 f0 ff ff       	call   f01016e4 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, NENV*sizeof(struct Env), PADDR(envs), PTE_U|PTE_P);
f01026ab:	8b 0d c8 5b 19 f0    	mov    0xf0195bc8,%ecx
f01026b1:	ba c5 00 00 00       	mov    $0xc5,%edx
f01026b6:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f01026bb:	e8 d7 e4 ff ff       	call   f0100b97 <_paddr>
f01026c0:	83 c4 08             	add    $0x8,%esp
f01026c3:	6a 05                	push   $0x5
f01026c5:	50                   	push   %eax
f01026c6:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01026cb:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01026d0:	a1 88 78 19 f0       	mov    0xf0197888,%eax
f01026d5:	e8 0a f0 ff ff       	call   f01016e4 <boot_map_region>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir,KSTACKTOP-KSTKSIZE,KSTKSIZE,PADDR(bootstack),PTE_P|PTE_W);
f01026da:	b9 00 70 10 f0       	mov    $0xf0107000,%ecx
f01026df:	ba d2 00 00 00       	mov    $0xd2,%edx
f01026e4:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
f01026e9:	e8 a9 e4 ff ff       	call   f0100b97 <_paddr>
f01026ee:	83 c4 08             	add    $0x8,%esp
f01026f1:	6a 03                	push   $0x3
f01026f3:	50                   	push   %eax
f01026f4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01026f9:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01026fe:	a1 88 78 19 f0       	mov    0xf0197888,%eax
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
f0102719:	a1 88 78 19 f0       	mov    0xf0197888,%eax
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
f0102728:	8b 0d 88 78 19 f0    	mov    0xf0197888,%ecx
f010272e:	ba e7 00 00 00       	mov    $0xe7,%edx
f0102733:	b8 5b 56 10 f0       	mov    $0xf010565b,%eax
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
f010276e:	57                   	push   %edi
f010276f:	56                   	push   %esi
f0102770:	53                   	push   %ebx
f0102771:	83 ec 2c             	sub    $0x2c,%esp
f0102774:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102777:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	uintptr_t xva = (uintptr_t) va;
	uintptr_t lim_va = xva+len;
f010277a:	89 c1                	mov    %eax,%ecx
f010277c:	03 4d 10             	add    0x10(%ebp),%ecx
f010277f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	if (xva >= ULIM){
f0102782:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0102787:	76 0c                	jbe    f0102795 <user_mem_check+0x2a>
		user_mem_check_addr = xva;
f0102789:	a3 bc 5b 19 f0       	mov    %eax,0xf0195bbc
		return -E_FAULT;
f010278e:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102793:	eb 6e                	jmp    f0102803 <user_mem_check+0x98>
f0102795:	89 c3                	mov    %eax,%ebx
	}
	if (lim_va >= ULIM || lim_va < xva){ //Bolzano dice que esto anda
f0102797:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010279a:	81 f9 ff ff 7f ef    	cmp    $0xef7fffff,%ecx
f01027a0:	77 07                	ja     f01027a9 <user_mem_check+0x3e>
		return -E_FAULT;		
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
		if (!page_lookup(env->env_pgdir,(void*) xva,&pteaddr)){	//si no esta alojada o !PTE_P
f01027a2:	8d 7d e4             	lea    -0x1c(%ebp),%edi
	uintptr_t lim_va = xva+len;
	if (xva >= ULIM){
		user_mem_check_addr = xva;
		return -E_FAULT;
	}
	if (lim_va >= ULIM || lim_va < xva){ //Bolzano dice que esto anda
f01027a5:	39 c8                	cmp    %ecx,%eax
f01027a7:	76 50                	jbe    f01027f9 <user_mem_check+0x8e>
		user_mem_check_addr = ULIM; 
f01027a9:	c7 05 bc 5b 19 f0 00 	movl   $0xef800000,0xf0195bbc
f01027b0:	00 80 ef 
		return -E_FAULT;		
f01027b3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027b8:	eb 49                	jmp    f0102803 <user_mem_check+0x98>
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
		if (!page_lookup(env->env_pgdir,(void*) xva,&pteaddr)){	//si no esta alojada o !PTE_P
f01027ba:	83 ec 04             	sub    $0x4,%esp
f01027bd:	57                   	push   %edi
f01027be:	53                   	push   %ebx
f01027bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01027c2:	ff 70 5c             	pushl  0x5c(%eax)
f01027c5:	e8 d3 ef ff ff       	call   f010179d <page_lookup>
f01027ca:	83 c4 10             	add    $0x10,%esp
f01027cd:	85 c0                	test   %eax,%eax
f01027cf:	75 0d                	jne    f01027de <user_mem_check+0x73>
			user_mem_check_addr = xva;
f01027d1:	89 1d bc 5b 19 f0    	mov    %ebx,0xf0195bbc
			return -E_FAULT;
f01027d7:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027dc:	eb 25                	jmp    f0102803 <user_mem_check+0x98>
		}
		if ((*pteaddr & perm) != perm){ //si no tiene permisos perm (PTE_P ya chequeado)
f01027de:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027e1:	89 f2                	mov    %esi,%edx
f01027e3:	23 10                	and    (%eax),%edx
f01027e5:	39 d6                	cmp    %edx,%esi
f01027e7:	74 0d                	je     f01027f6 <user_mem_check+0x8b>
			user_mem_check_addr = xva;
f01027e9:	89 1d bc 5b 19 f0    	mov    %ebx,0xf0195bbc
			return -E_FAULT;
f01027ef:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01027f4:	eb 0d                	jmp    f0102803 <user_mem_check+0x98>
		}
		ROUNDUP(++xva,PGSIZE);
f01027f6:	83 c3 01             	add    $0x1,%ebx
		user_mem_check_addr = ULIM; 
		return -E_FAULT;		
	}

	pte_t* pteaddr;
	while(xva<lim_va){ 
f01027f9:	3b 5d d4             	cmp    -0x2c(%ebp),%ebx
f01027fc:	72 bc                	jb     f01027ba <user_mem_check+0x4f>
			user_mem_check_addr = xva;
			return -E_FAULT;
		}
		ROUNDUP(++xva,PGSIZE);
	}
	return 0;
f01027fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102803:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102806:	5b                   	pop    %ebx
f0102807:	5e                   	pop    %esi
f0102808:	5f                   	pop    %edi
f0102809:	5d                   	pop    %ebp
f010280a:	c3                   	ret    

f010280b <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010280b:	55                   	push   %ebp
f010280c:	89 e5                	mov    %esp,%ebp
f010280e:	53                   	push   %ebx
f010280f:	83 ec 04             	sub    $0x4,%esp
f0102812:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102815:	8b 45 14             	mov    0x14(%ebp),%eax
f0102818:	83 c8 04             	or     $0x4,%eax
f010281b:	50                   	push   %eax
f010281c:	ff 75 10             	pushl  0x10(%ebp)
f010281f:	ff 75 0c             	pushl  0xc(%ebp)
f0102822:	53                   	push   %ebx
f0102823:	e8 43 ff ff ff       	call   f010276b <user_mem_check>
f0102828:	83 c4 10             	add    $0x10,%esp
f010282b:	85 c0                	test   %eax,%eax
f010282d:	79 21                	jns    f0102850 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f010282f:	83 ec 04             	sub    $0x4,%esp
f0102832:	ff 35 bc 5b 19 f0    	pushl  0xf0195bbc
f0102838:	ff 73 48             	pushl  0x48(%ebx)
f010283b:	68 18 56 10 f0       	push   $0xf0105618
f0102840:	e8 3d 08 00 00       	call   f0103082 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102845:	89 1c 24             	mov    %ebx,(%esp)
f0102848:	e8 ab 06 00 00       	call   f0102ef8 <env_destroy>
f010284d:	83 c4 10             	add    $0x10,%esp
	}
}
f0102850:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102853:	c9                   	leave  
f0102854:	c3                   	ret    

f0102855 <lgdt>:
	asm volatile("lidt (%0)" : : "r" (p));
}

static inline void
lgdt(void *p)
{
f0102855:	55                   	push   %ebp
f0102856:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f0102858:	0f 01 10             	lgdtl  (%eax)
}
f010285b:	5d                   	pop    %ebp
f010285c:	c3                   	ret    

f010285d <lldt>:

static inline void
lldt(uint16_t sel)
{
f010285d:	55                   	push   %ebp
f010285e:	89 e5                	mov    %esp,%ebp
	asm volatile("lldt %0" : : "r" (sel));
f0102860:	0f 00 d0             	lldt   %ax
}
f0102863:	5d                   	pop    %ebp
f0102864:	c3                   	ret    

f0102865 <lcr3>:
	return val;
}

static inline void
lcr3(uint32_t val)
{
f0102865:	55                   	push   %ebp
f0102866:	89 e5                	mov    %esp,%ebp
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102868:	0f 22 d8             	mov    %eax,%cr3
}
f010286b:	5d                   	pop    %ebp
f010286c:	c3                   	ret    

f010286d <rcr3>:

static inline uint32_t
rcr3(void)
{
f010286d:	55                   	push   %ebp
f010286e:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr3,%0" : "=r" (val));
f0102870:	0f 20 d8             	mov    %cr3,%eax
	return val;
}
f0102873:	5d                   	pop    %ebp
f0102874:	c3                   	ret    

f0102875 <page2pa>:
int	user_mem_check(struct Env *env, const void *va, size_t len, int perm);
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
f0102875:	55                   	push   %ebp
f0102876:	89 e5                	mov    %esp,%ebp
	return (pp - pages) << PGSHIFT;
f0102878:	2b 05 8c 78 19 f0    	sub    0xf019788c,%eax
f010287e:	c1 f8 03             	sar    $0x3,%eax
f0102881:	c1 e0 0c             	shl    $0xc,%eax
}
f0102884:	5d                   	pop    %ebp
f0102885:	c3                   	ret    

f0102886 <_kaddr>:
 * virtual address.  It panics if you pass an invalid physical address. */
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
f0102886:	55                   	push   %ebp
f0102887:	89 e5                	mov    %esp,%ebp
f0102889:	53                   	push   %ebx
f010288a:	83 ec 04             	sub    $0x4,%esp
	if (PGNUM(pa) >= npages)
f010288d:	89 cb                	mov    %ecx,%ebx
f010288f:	c1 eb 0c             	shr    $0xc,%ebx
f0102892:	3b 1d 84 78 19 f0    	cmp    0xf0197884,%ebx
f0102898:	72 0d                	jb     f01028a7 <_kaddr+0x21>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010289a:	51                   	push   %ecx
f010289b:	68 a0 4e 10 f0       	push   $0xf0104ea0
f01028a0:	52                   	push   %edx
f01028a1:	50                   	push   %eax
f01028a2:	e8 02 d8 ff ff       	call   f01000a9 <_panic>
	return (void *)(pa + KERNBASE);
f01028a7:	8d 81 00 00 00 f0    	lea    -0x10000000(%ecx),%eax
}
f01028ad:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01028b0:	c9                   	leave  
f01028b1:	c3                   	ret    

f01028b2 <page2kva>:
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01028b2:	55                   	push   %ebp
f01028b3:	89 e5                	mov    %esp,%ebp
f01028b5:	83 ec 08             	sub    $0x8,%esp
	return KADDR(page2pa(pp));
f01028b8:	e8 b8 ff ff ff       	call   f0102875 <page2pa>
f01028bd:	89 c1                	mov    %eax,%ecx
f01028bf:	ba 56 00 00 00       	mov    $0x56,%edx
f01028c4:	b8 4d 56 10 f0       	mov    $0xf010564d,%eax
f01028c9:	e8 b8 ff ff ff       	call   f0102886 <_kaddr>
}
f01028ce:	c9                   	leave  
f01028cf:	c3                   	ret    

f01028d0 <_paddr>:
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028d0:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01028d6:	77 13                	ja     f01028eb <_paddr+0x1b>
 */
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
f01028d8:	55                   	push   %ebp
f01028d9:	89 e5                	mov    %esp,%ebp
f01028db:	83 ec 08             	sub    $0x8,%esp
	if ((uint32_t)kva < KERNBASE)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028de:	51                   	push   %ecx
f01028df:	68 c4 4e 10 f0       	push   $0xf0104ec4
f01028e4:	52                   	push   %edx
f01028e5:	50                   	push   %eax
f01028e6:	e8 be d7 ff ff       	call   f01000a9 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028eb:	8d 81 00 00 00 10    	lea    0x10000000(%ecx),%eax
}
f01028f1:	c3                   	ret    

f01028f2 <env_setup_vm>:
// Returns 0 on success, < 0 on error.  Errors include:
//	-E_NO_MEM if page directory or table could not be allocated.
//
static int
env_setup_vm(struct Env *e)
{
f01028f2:	55                   	push   %ebp
f01028f3:	89 e5                	mov    %esp,%ebp
f01028f5:	56                   	push   %esi
f01028f6:	53                   	push   %ebx
f01028f7:	89 c6                	mov    %eax,%esi
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01028f9:	83 ec 0c             	sub    $0xc,%esp
f01028fc:	6a 01                	push   $0x1
f01028fe:	e8 b7 e8 ff ff       	call   f01011ba <page_alloc>
f0102903:	83 c4 10             	add    $0x10,%esp
f0102906:	85 c0                	test   %eax,%eax
f0102908:	74 4a                	je     f0102954 <env_setup_vm+0x62>
f010290a:	89 c3                	mov    %eax,%ebx
	//    - Note: In general, pp_ref is not maintained for
	//	physical pages mapped only above UTOP, but env_pgdir
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.
	e->env_pgdir = page2kva(p);
f010290c:	e8 a1 ff ff ff       	call   f01028b2 <page2kva>
f0102911:	89 46 5c             	mov    %eax,0x5c(%esi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0102914:	83 ec 04             	sub    $0x4,%esp
f0102917:	68 00 10 00 00       	push   $0x1000
f010291c:	ff 35 88 78 19 f0    	pushl  0xf0197888
f0102922:	50                   	push   %eax
f0102923:	e8 17 1c 00 00       	call   f010453f <memcpy>
	p->pp_ref ++;
f0102928:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	
	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010292d:	8b 5e 5c             	mov    0x5c(%esi),%ebx
f0102930:	89 d9                	mov    %ebx,%ecx
f0102932:	ba c2 00 00 00       	mov    $0xc2,%edx
f0102937:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f010293c:	e8 8f ff ff ff       	call   f01028d0 <_paddr>
f0102941:	83 c8 05             	or     $0x5,%eax
f0102944:	89 83 f4 0e 00 00    	mov    %eax,0xef4(%ebx)

	return 0;
f010294a:	83 c4 10             	add    $0x10,%esp
f010294d:	b8 00 00 00 00       	mov    $0x0,%eax
f0102952:	eb 05                	jmp    f0102959 <env_setup_vm+0x67>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102954:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;

	return 0;
}
f0102959:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010295c:	5b                   	pop    %ebx
f010295d:	5e                   	pop    %esi
f010295e:	5d                   	pop    %ebp
f010295f:	c3                   	ret    

f0102960 <pa2page>:
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102960:	c1 e8 0c             	shr    $0xc,%eax
f0102963:	3b 05 84 78 19 f0    	cmp    0xf0197884,%eax
f0102969:	72 17                	jb     f0102982 <pa2page+0x22>
	return (pp - pages) << PGSHIFT;
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
f010296b:	55                   	push   %ebp
f010296c:	89 e5                	mov    %esp,%ebp
f010296e:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
		panic("pa2page called with invalid pa");
f0102971:	68 d4 50 10 f0       	push   $0xf01050d4
f0102976:	6a 4f                	push   $0x4f
f0102978:	68 4d 56 10 f0       	push   $0xf010564d
f010297d:	e8 27 d7 ff ff       	call   f01000a9 <_panic>
	return &pages[PGNUM(pa)];
f0102982:	8b 15 8c 78 19 f0    	mov    0xf019788c,%edx
f0102988:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010298b:	c3                   	ret    

f010298c <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010298c:	55                   	push   %ebp
f010298d:	89 e5                	mov    %esp,%ebp
f010298f:	57                   	push   %edi
f0102990:	56                   	push   %esi
f0102991:	53                   	push   %ebx
f0102992:	83 ec 1c             	sub    $0x1c,%esp
f0102995:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	
	va = ROUNDDOWN(va,PGSIZE);
f0102997:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010299d:	89 d6                	mov    %edx,%esi
	void* va_finish = ROUNDUP(va+len,PGSIZE);
f010299f:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f01029a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01029ab:	89 c1                	mov    %eax,%ecx
f01029ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if (va_finish>va) {
		len = va_finish - va; //es un multiplo de PGSIZE	
f01029b0:	29 d0                	sub    %edx,%eax
f01029b2:	89 d3                	mov    %edx,%ebx
f01029b4:	f7 db                	neg    %ebx
f01029b6:	39 ca                	cmp    %ecx,%edx
f01029b8:	0f 42 d8             	cmovb  %eax,%ebx
f01029bb:	eb 5f                	jmp    f0102a1c <region_alloc+0x90>
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	while (len>0){
		struct PageInfo* page = page_alloc(0);//no hay que inicializar
f01029bd:	83 ec 0c             	sub    $0xc,%esp
f01029c0:	6a 00                	push   $0x0
f01029c2:	e8 f3 e7 ff ff       	call   f01011ba <page_alloc>
		if (page == NULL) panic("Error allocating environment");
f01029c7:	83 c4 10             	add    $0x10,%esp
f01029ca:	85 c0                	test   %eax,%eax
f01029cc:	75 17                	jne    f01029e5 <region_alloc+0x59>
f01029ce:	83 ec 04             	sub    $0x4,%esp
f01029d1:	68 f1 59 10 f0       	push   $0xf01059f1
f01029d6:	68 22 01 00 00       	push   $0x122
f01029db:	68 e6 59 10 f0       	push   $0xf01059e6
f01029e0:	e8 c4 d6 ff ff       	call   f01000a9 <_panic>

		int ret_code = page_insert(e->env_pgdir, page, va, PTE_W | PTE_U);
f01029e5:	6a 06                	push   $0x6
f01029e7:	56                   	push   %esi
f01029e8:	50                   	push   %eax
f01029e9:	ff 77 5c             	pushl  0x5c(%edi)
f01029ec:	e8 47 ee ff ff       	call   f0101838 <page_insert>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
f01029f1:	83 c4 10             	add    $0x10,%esp
f01029f4:	83 f8 fc             	cmp    $0xfffffffc,%eax
f01029f7:	75 17                	jne    f0102a10 <region_alloc+0x84>
f01029f9:	83 ec 04             	sub    $0x4,%esp
f01029fc:	68 f1 59 10 f0       	push   $0xf01059f1
f0102a01:	68 25 01 00 00       	push   $0x125
f0102a06:	68 e6 59 10 f0       	push   $0xf01059e6
f0102a0b:	e8 99 d6 ff ff       	call   f01000a9 <_panic>
		
		va+=PGSIZE;
f0102a10:	81 c6 00 10 00 00    	add    $0x1000,%esi
		len-=PGSIZE;
f0102a16:	81 eb 00 10 00 00    	sub    $0x1000,%ebx
		len = va_finish - va; //es un multiplo de PGSIZE	
	}
	else {
		len = ~0x0-(uint32_t)va+1;//si hizo overflow
	}
	while (len>0){
f0102a1c:	85 db                	test   %ebx,%ebx
f0102a1e:	75 9d                	jne    f01029bd <region_alloc+0x31>
		if (ret_code == -E_NO_MEM)	panic("Error allocating environment");
		
		va+=PGSIZE;
		len-=PGSIZE;
	}
	assert(va==va_finish);
f0102a20:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0102a23:	74 19                	je     f0102a3e <region_alloc+0xb2>
f0102a25:	68 0e 5a 10 f0       	push   $0xf0105a0e
f0102a2a:	68 7a 56 10 f0       	push   $0xf010567a
f0102a2f:	68 2a 01 00 00       	push   $0x12a
f0102a34:	68 e6 59 10 f0       	push   $0xf01059e6
f0102a39:	e8 6b d6 ff ff       	call   f01000a9 <_panic>
}
f0102a3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a41:	5b                   	pop    %ebx
f0102a42:	5e                   	pop    %esi
f0102a43:	5f                   	pop    %edi
f0102a44:	5d                   	pop    %ebp
f0102a45:	c3                   	ret    

f0102a46 <load_icode>:
// load_icode panics if it encounters problems.
//  - How might load_icode fail?  What might be wrong with the given input?
//
static void
load_icode(struct Env *e, uint8_t *binary)
{
f0102a46:	55                   	push   %ebp
f0102a47:	89 e5                	mov    %esp,%ebp
f0102a49:	57                   	push   %edi
f0102a4a:	56                   	push   %esi
f0102a4b:	53                   	push   %ebx
f0102a4c:	83 ec 1c             	sub    $0x1c,%esp
f0102a4f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a52:	89 d7                	mov    %edx,%edi
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	
	assert(rcr3()==PADDR(kern_pgdir));
f0102a54:	e8 14 fe ff ff       	call   f010286d <rcr3>
f0102a59:	89 c3                	mov    %eax,%ebx
f0102a5b:	8b 0d 88 78 19 f0    	mov    0xf0197888,%ecx
f0102a61:	ba 64 01 00 00       	mov    $0x164,%edx
f0102a66:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102a6b:	e8 60 fe ff ff       	call   f01028d0 <_paddr>
f0102a70:	39 c3                	cmp    %eax,%ebx
f0102a72:	74 19                	je     f0102a8d <load_icode+0x47>
f0102a74:	68 1c 5a 10 f0       	push   $0xf0105a1c
f0102a79:	68 7a 56 10 f0       	push   $0xf010567a
f0102a7e:	68 64 01 00 00       	push   $0x164
f0102a83:	68 e6 59 10 f0       	push   $0xf01059e6
f0102a88:	e8 1c d6 ff ff       	call   f01000a9 <_panic>
	lcr3(PADDR(e->env_pgdir));//cambio a pgdir del env para que anden memcpy y memset
f0102a8d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102a90:	8b 4e 5c             	mov    0x5c(%esi),%ecx
f0102a93:	ba 65 01 00 00       	mov    $0x165,%edx
f0102a98:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102a9d:	e8 2e fe ff ff       	call   f01028d0 <_paddr>
f0102aa2:	e8 be fd ff ff       	call   f0102865 <lcr3>
	assert(rcr3()==PADDR(e->env_pgdir));
f0102aa7:	e8 c1 fd ff ff       	call   f010286d <rcr3>
f0102aac:	89 c3                	mov    %eax,%ebx
f0102aae:	8b 4e 5c             	mov    0x5c(%esi),%ecx
f0102ab1:	ba 66 01 00 00       	mov    $0x166,%edx
f0102ab6:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102abb:	e8 10 fe ff ff       	call   f01028d0 <_paddr>
f0102ac0:	39 c3                	cmp    %eax,%ebx
f0102ac2:	74 19                	je     f0102add <load_icode+0x97>
f0102ac4:	68 36 5a 10 f0       	push   $0xf0105a36
f0102ac9:	68 7a 56 10 f0       	push   $0xf010567a
f0102ace:	68 66 01 00 00       	push   $0x166
f0102ad3:	68 e6 59 10 f0       	push   $0xf01059e6
f0102ad8:	e8 cc d5 ff ff       	call   f01000a9 <_panic>

	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");
f0102add:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102ae3:	74 17                	je     f0102afc <load_icode+0xb6>
f0102ae5:	83 ec 04             	sub    $0x4,%esp
f0102ae8:	68 52 5a 10 f0       	push   $0xf0105a52
f0102aed:	68 69 01 00 00       	push   $0x169
f0102af2:	68 e6 59 10 f0       	push   $0xf01059e6
f0102af7:	e8 ad d5 ff ff       	call   f01000a9 <_panic>

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
f0102afc:	89 fb                	mov    %edi,%ebx
f0102afe:	03 5f 1c             	add    0x1c(%edi),%ebx
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++,ph++){
f0102b01:	be 00 00 00 00       	mov    $0x0,%esi
f0102b06:	eb 4c                	jmp    f0102b54 <load_icode+0x10e>
		va=(void*) ph->p_va;
		if (ph->p_type != ELF_PROG_LOAD) continue;
f0102b08:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102b0b:	75 41                	jne    f0102b4e <load_icode+0x108>
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++,ph++){
		va=(void*) ph->p_va;
f0102b0d:	8b 43 08             	mov    0x8(%ebx),%eax
		if (ph->p_type != ELF_PROG_LOAD) continue;
		region_alloc(e,va,ph->p_memsz);
f0102b10:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102b13:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102b16:	89 c2                	mov    %eax,%edx
f0102b18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102b1b:	e8 6c fe ff ff       	call   f010298c <region_alloc>
		memcpy(va,(void*)binary+ph->p_offset,ph->p_filesz);
f0102b20:	83 ec 04             	sub    $0x4,%esp
f0102b23:	ff 73 10             	pushl  0x10(%ebx)
f0102b26:	89 f9                	mov    %edi,%ecx
f0102b28:	03 4b 04             	add    0x4(%ebx),%ecx
f0102b2b:	51                   	push   %ecx
f0102b2c:	ff 75 e0             	pushl  -0x20(%ebp)
f0102b2f:	e8 0b 1a 00 00       	call   f010453f <memcpy>
		memset(va + ph->p_filesz,0,ph->p_memsz - ph->p_filesz);//VA+FILESZ->VA+MEMSZ
f0102b34:	8b 43 10             	mov    0x10(%ebx),%eax
f0102b37:	83 c4 0c             	add    $0xc,%esp
f0102b3a:	8b 53 14             	mov    0x14(%ebx),%edx
f0102b3d:	29 c2                	sub    %eax,%edx
f0102b3f:	52                   	push   %edx
f0102b40:	6a 00                	push   $0x0
f0102b42:	03 45 e0             	add    -0x20(%ebp),%eax
f0102b45:	50                   	push   %eax
f0102b46:	e8 3e 19 00 00       	call   f0104489 <memset>
f0102b4b:	83 c4 10             	add    $0x10,%esp
	struct Elf* elf = (struct Elf *) binary;
	if (elf->e_magic != ELF_MAGIC) panic("Invalid binary");

	struct Proghdr* ph = (struct Proghdr*)(binary + elf->e_phoff);
	void* va;
	for (int hdr_num = 0; hdr_num < elf->e_phnum; hdr_num++,ph++){
f0102b4e:	83 c6 01             	add    $0x1,%esi
f0102b51:	83 c3 20             	add    $0x20,%ebx
f0102b54:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0102b58:	39 c6                	cmp    %eax,%esi
f0102b5a:	7c ac                	jl     f0102b08 <load_icode+0xc2>
		//ph++;
		//ph += elf->e_phentsize;
	}


	e->env_tf.tf_eip=elf->e_entry;
f0102b5c:	8b 47 18             	mov    0x18(%edi),%eax
f0102b5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102b62:	89 47 30             	mov    %eax,0x30(%edi)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.

	region_alloc(e,(void*)(USTACKTOP - PGSIZE),PGSIZE);
f0102b65:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102b6a:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102b6f:	89 f8                	mov    %edi,%eax
f0102b71:	e8 16 fe ff ff       	call   f010298c <region_alloc>

	lcr3(PADDR(kern_pgdir));//vuelvo a poner el pgdir del kernel 
f0102b76:	8b 0d 88 78 19 f0    	mov    0xf0197888,%ecx
f0102b7c:	ba 81 01 00 00       	mov    $0x181,%edx
f0102b81:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102b86:	e8 45 fd ff ff       	call   f01028d0 <_paddr>
f0102b8b:	e8 d5 fc ff ff       	call   f0102865 <lcr3>
}
f0102b90:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102b93:	5b                   	pop    %ebx
f0102b94:	5e                   	pop    %esi
f0102b95:	5f                   	pop    %edi
f0102b96:	5d                   	pop    %ebp
f0102b97:	c3                   	ret    

f0102b98 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102b98:	55                   	push   %ebp
f0102b99:	89 e5                	mov    %esp,%ebp
f0102b9b:	8b 55 08             	mov    0x8(%ebp),%edx
f0102b9e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102ba1:	85 d2                	test   %edx,%edx
f0102ba3:	75 11                	jne    f0102bb6 <envid2env+0x1e>
		*env_store = curenv;
f0102ba5:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f0102baa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102bad:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102baf:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bb4:	eb 5e                	jmp    f0102c14 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102bb6:	89 d0                	mov    %edx,%eax
f0102bb8:	25 ff 03 00 00       	and    $0x3ff,%eax
f0102bbd:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102bc0:	c1 e0 05             	shl    $0x5,%eax
f0102bc3:	03 05 c8 5b 19 f0    	add    0xf0195bc8,%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102bc9:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0102bcd:	74 05                	je     f0102bd4 <envid2env+0x3c>
f0102bcf:	3b 50 48             	cmp    0x48(%eax),%edx
f0102bd2:	74 10                	je     f0102be4 <envid2env+0x4c>
		*env_store = 0;
f0102bd4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bd7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102bdd:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102be2:	eb 30                	jmp    f0102c14 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102be4:	84 c9                	test   %cl,%cl
f0102be6:	74 22                	je     f0102c0a <envid2env+0x72>
f0102be8:	8b 15 c4 5b 19 f0    	mov    0xf0195bc4,%edx
f0102bee:	39 d0                	cmp    %edx,%eax
f0102bf0:	74 18                	je     f0102c0a <envid2env+0x72>
f0102bf2:	8b 4a 48             	mov    0x48(%edx),%ecx
f0102bf5:	39 48 4c             	cmp    %ecx,0x4c(%eax)
f0102bf8:	74 10                	je     f0102c0a <envid2env+0x72>
		*env_store = 0;
f0102bfa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bfd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102c03:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102c08:	eb 0a                	jmp    f0102c14 <envid2env+0x7c>
	}

	*env_store = e;
f0102c0a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102c0d:	89 01                	mov    %eax,(%ecx)
	return 0;
f0102c0f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c14:	5d                   	pop    %ebp
f0102c15:	c3                   	ret    

f0102c16 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102c16:	55                   	push   %ebp
f0102c17:	89 e5                	mov    %esp,%ebp
	lgdt(&gdt_pd);
f0102c19:	b8 00 03 11 f0       	mov    $0xf0110300,%eax
f0102c1e:	e8 32 fc ff ff       	call   f0102855 <lgdt>
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" : : "a"(GD_UD | 3));
f0102c23:	b8 23 00 00 00       	mov    $0x23,%eax
f0102c28:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a"(GD_UD | 3));
f0102c2a:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" : : "a"(GD_KD));
f0102c2c:	b8 10 00 00 00       	mov    $0x10,%eax
f0102c31:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a"(GD_KD));
f0102c33:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a"(GD_KD));
f0102c35:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i"(GD_KT));
f0102c37:	ea 3e 2c 10 f0 08 00 	ljmp   $0x8,$0xf0102c3e
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
f0102c3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c43:	e8 15 fc ff ff       	call   f010285d <lldt>
}
f0102c48:	5d                   	pop    %ebp
f0102c49:	c3                   	ret    

f0102c4a <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
		envs[i].env_status = ENV_FREE; 
f0102c4a:	8b 15 c8 5b 19 f0    	mov    0xf0195bc8,%edx
f0102c50:	8d 42 60             	lea    0x60(%edx),%eax
f0102c53:	81 c2 00 80 01 00    	add    $0x18000,%edx
f0102c59:	c7 40 f4 00 00 00 00 	movl   $0x0,-0xc(%eax)
		envs[i].env_id = 0;
f0102c60:	c7 40 e8 00 00 00 00 	movl   $0x0,-0x18(%eax)
		envs[i].env_link = &envs[i+1];
f0102c67:	89 40 e4             	mov    %eax,-0x1c(%eax)
f0102c6a:	83 c0 60             	add    $0x60,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here. (OK)
	
	for (size_t i=0; i< NENV-1; i++){
f0102c6d:	39 d0                	cmp    %edx,%eax
f0102c6f:	75 e8                	jne    f0102c59 <env_init+0xf>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102c71:	55                   	push   %ebp
f0102c72:	89 e5                	mov    %esp,%ebp
		envs[i].env_status = ENV_FREE; 
		envs[i].env_id = 0;
		envs[i].env_link = &envs[i+1];
		
	}
	envs[NENV-1].env_status = ENV_FREE;
f0102c74:	a1 c8 5b 19 f0       	mov    0xf0195bc8,%eax
f0102c79:	c7 80 f4 7f 01 00 00 	movl   $0x0,0x17ff4(%eax)
f0102c80:	00 00 00 
	envs[NENV-1].env_id = 0;
f0102c83:	c7 80 e8 7f 01 00 00 	movl   $0x0,0x17fe8(%eax)
f0102c8a:	00 00 00 
	env_free_list = &envs[0];
f0102c8d:	a3 cc 5b 19 f0       	mov    %eax,0xf0195bcc
	// Per-CPU part of the initialization
	env_init_percpu();
f0102c92:	e8 7f ff ff ff       	call   f0102c16 <env_init_percpu>
}
f0102c97:	5d                   	pop    %ebp
f0102c98:	c3                   	ret    

f0102c99 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102c99:	55                   	push   %ebp
f0102c9a:	89 e5                	mov    %esp,%ebp
f0102c9c:	53                   	push   %ebx
f0102c9d:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102ca0:	8b 1d cc 5b 19 f0    	mov    0xf0195bcc,%ebx
f0102ca6:	85 db                	test   %ebx,%ebx
f0102ca8:	0f 84 c0 00 00 00    	je     f0102d6e <env_alloc+0xd5>
		return -E_NO_FREE_ENV;

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
f0102cae:	89 d8                	mov    %ebx,%eax
f0102cb0:	e8 3d fc ff ff       	call   f01028f2 <env_setup_vm>
f0102cb5:	85 c0                	test   %eax,%eax
f0102cb7:	0f 88 b6 00 00 00    	js     f0102d73 <env_alloc+0xda>
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102cbd:	8b 43 48             	mov    0x48(%ebx),%eax
f0102cc0:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)  // Don't create a negative env_id.
f0102cc5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102cca:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102ccf:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102cd2:	89 da                	mov    %ebx,%edx
f0102cd4:	2b 15 c8 5b 19 f0    	sub    0xf0195bc8,%edx
f0102cda:	c1 fa 05             	sar    $0x5,%edx
f0102cdd:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0102ce3:	09 d0                	or     %edx,%eax
f0102ce5:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102ce8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ceb:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102cee:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102cf5:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102cfc:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102d03:	83 ec 04             	sub    $0x4,%esp
f0102d06:	6a 44                	push   $0x44
f0102d08:	6a 00                	push   $0x0
f0102d0a:	53                   	push   %ebx
f0102d0b:	e8 79 17 00 00       	call   f0104489 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102d10:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102d16:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102d1c:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102d22:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102d29:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0102d2f:	8b 43 44             	mov    0x44(%ebx),%eax
f0102d32:	a3 cc 5b 19 f0       	mov    %eax,0xf0195bcc
	*newenv_store = e; 
f0102d37:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d3a:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102d3c:	8b 53 48             	mov    0x48(%ebx),%edx
f0102d3f:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f0102d44:	83 c4 10             	add    $0x10,%esp
f0102d47:	85 c0                	test   %eax,%eax
f0102d49:	74 05                	je     f0102d50 <env_alloc+0xb7>
f0102d4b:	8b 40 48             	mov    0x48(%eax),%eax
f0102d4e:	eb 05                	jmp    f0102d55 <env_alloc+0xbc>
f0102d50:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d55:	83 ec 04             	sub    $0x4,%esp
f0102d58:	52                   	push   %edx
f0102d59:	50                   	push   %eax
f0102d5a:	68 61 5a 10 f0       	push   $0xf0105a61
f0102d5f:	e8 1e 03 00 00       	call   f0103082 <cprintf>
	return 0;
f0102d64:	83 c4 10             	add    $0x10,%esp
f0102d67:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d6c:	eb 05                	jmp    f0102d73 <env_alloc+0xda>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102d6e:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
	env_free_list = e->env_link;
	*newenv_store = e; 

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102d73:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102d76:	c9                   	leave  
f0102d77:	c3                   	ret    

f0102d78 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102d78:	55                   	push   %ebp
f0102d79:	89 e5                	mov    %esp,%ebp
f0102d7b:	83 ec 20             	sub    $0x20,%esp
	// LAB 3: Your code here.
	struct Env* e;
	int err = env_alloc(&e,0);//hace lugar para un Env cuya dir se guarda en e, parent_id es 0 por def.
f0102d7e:	6a 00                	push   $0x0
f0102d80:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d83:	50                   	push   %eax
f0102d84:	e8 10 ff ff ff       	call   f0102c99 <env_alloc>
	if (err<0) panic("env_create: %e", err);
f0102d89:	83 c4 10             	add    $0x10,%esp
f0102d8c:	85 c0                	test   %eax,%eax
f0102d8e:	79 15                	jns    f0102da5 <env_create+0x2d>
f0102d90:	50                   	push   %eax
f0102d91:	68 76 5a 10 f0       	push   $0xf0105a76
f0102d96:	68 91 01 00 00       	push   $0x191
f0102d9b:	68 e6 59 10 f0       	push   $0xf01059e6
f0102da0:	e8 04 d3 ff ff       	call   f01000a9 <_panic>
	load_icode(e,binary);
f0102da5:	8b 55 08             	mov    0x8(%ebp),%edx
f0102da8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102dab:	e8 96 fc ff ff       	call   f0102a46 <load_icode>
	e->env_type = type;
f0102db0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102db3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102db6:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102db9:	c9                   	leave  
f0102dba:	c3                   	ret    

f0102dbb <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102dbb:	55                   	push   %ebp
f0102dbc:	89 e5                	mov    %esp,%ebp
f0102dbe:	57                   	push   %edi
f0102dbf:	56                   	push   %esi
f0102dc0:	53                   	push   %ebx
f0102dc1:	83 ec 1c             	sub    $0x1c,%esp
f0102dc4:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102dc7:	39 3d c4 5b 19 f0    	cmp    %edi,0xf0195bc4
f0102dcd:	75 1a                	jne    f0102de9 <env_free+0x2e>
		lcr3(PADDR(kern_pgdir));
f0102dcf:	8b 0d 88 78 19 f0    	mov    0xf0197888,%ecx
f0102dd5:	ba a4 01 00 00       	mov    $0x1a4,%edx
f0102dda:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102ddf:	e8 ec fa ff ff       	call   f01028d0 <_paddr>
f0102de4:	e8 7c fa ff ff       	call   f0102865 <lcr3>

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102de9:	8b 57 48             	mov    0x48(%edi),%edx
f0102dec:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f0102df1:	85 c0                	test   %eax,%eax
f0102df3:	74 05                	je     f0102dfa <env_free+0x3f>
f0102df5:	8b 40 48             	mov    0x48(%eax),%eax
f0102df8:	eb 05                	jmp    f0102dff <env_free+0x44>
f0102dfa:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dff:	83 ec 04             	sub    $0x4,%esp
f0102e02:	52                   	push   %edx
f0102e03:	50                   	push   %eax
f0102e04:	68 85 5a 10 f0       	push   $0xf0105a85
f0102e09:	e8 74 02 00 00       	call   f0103082 <cprintf>
f0102e0e:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e11:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102e18:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102e1b:	89 c8                	mov    %ecx,%eax
f0102e1d:	c1 e0 02             	shl    $0x2,%eax
f0102e20:	89 45 dc             	mov    %eax,-0x24(%ebp)
		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102e23:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e26:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102e29:	a8 01                	test   $0x1,%al
f0102e2b:	74 72                	je     f0102e9f <env_free+0xe4>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102e2d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e32:	89 45 d8             	mov    %eax,-0x28(%ebp)
		pt = (pte_t *) KADDR(pa);
f0102e35:	89 c1                	mov    %eax,%ecx
f0102e37:	ba b2 01 00 00       	mov    $0x1b2,%edx
f0102e3c:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102e41:	e8 40 fa ff ff       	call   f0102886 <_kaddr>
f0102e46:	89 c6                	mov    %eax,%esi

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102e48:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102e4b:	c1 e0 16             	shl    $0x16,%eax
f0102e4e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102e51:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102e56:	f6 04 9e 01          	testb  $0x1,(%esi,%ebx,4)
f0102e5a:	74 17                	je     f0102e73 <env_free+0xb8>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102e5c:	83 ec 08             	sub    $0x8,%esp
f0102e5f:	89 d8                	mov    %ebx,%eax
f0102e61:	c1 e0 0c             	shl    $0xc,%eax
f0102e64:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102e67:	50                   	push   %eax
f0102e68:	ff 77 5c             	pushl  0x5c(%edi)
f0102e6b:	e8 82 e9 ff ff       	call   f01017f2 <page_remove>
f0102e70:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t *) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102e73:	83 c3 01             	add    $0x1,%ebx
f0102e76:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102e7c:	75 d8                	jne    f0102e56 <env_free+0x9b>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102e7e:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e81:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102e84:	c7 04 08 00 00 00 00 	movl   $0x0,(%eax,%ecx,1)
		page_decref(pa2page(pa));
f0102e8b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e8e:	e8 cd fa ff ff       	call   f0102960 <pa2page>
f0102e93:	83 ec 0c             	sub    $0xc,%esp
f0102e96:	50                   	push   %eax
f0102e97:	e8 82 e7 ff ff       	call   f010161e <page_decref>
f0102e9c:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102e9f:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0102ea3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ea6:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102eab:	0f 85 67 ff ff ff    	jne    f0102e18 <env_free+0x5d>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0102eb1:	8b 4f 5c             	mov    0x5c(%edi),%ecx
f0102eb4:	ba c0 01 00 00       	mov    $0x1c0,%edx
f0102eb9:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102ebe:	e8 0d fa ff ff       	call   f01028d0 <_paddr>
	e->env_pgdir = 0;
f0102ec3:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	page_decref(pa2page(pa));
f0102eca:	e8 91 fa ff ff       	call   f0102960 <pa2page>
f0102ecf:	83 ec 0c             	sub    $0xc,%esp
f0102ed2:	50                   	push   %eax
f0102ed3:	e8 46 e7 ff ff       	call   f010161e <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0102ed8:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0102edf:	a1 cc 5b 19 f0       	mov    0xf0195bcc,%eax
f0102ee4:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0102ee7:	89 3d cc 5b 19 f0    	mov    %edi,0xf0195bcc
}
f0102eed:	83 c4 10             	add    $0x10,%esp
f0102ef0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ef3:	5b                   	pop    %ebx
f0102ef4:	5e                   	pop    %esi
f0102ef5:	5f                   	pop    %edi
f0102ef6:	5d                   	pop    %ebp
f0102ef7:	c3                   	ret    

f0102ef8 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0102ef8:	55                   	push   %ebp
f0102ef9:	89 e5                	mov    %esp,%ebp
f0102efb:	83 ec 14             	sub    $0x14,%esp
	env_free(e);
f0102efe:	ff 75 08             	pushl  0x8(%ebp)
f0102f01:	e8 b5 fe ff ff       	call   f0102dbb <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0102f06:	c7 04 24 8c 59 10 f0 	movl   $0xf010598c,(%esp)
f0102f0d:	e8 70 01 00 00       	call   f0103082 <cprintf>
f0102f12:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0102f15:	83 ec 0c             	sub    $0xc,%esp
f0102f18:	6a 00                	push   $0x0
f0102f1a:	e8 a7 da ff ff       	call   f01009c6 <monitor>
f0102f1f:	83 c4 10             	add    $0x10,%esp
f0102f22:	eb f1                	jmp    f0102f15 <env_destroy+0x1d>

f0102f24 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0102f24:	55                   	push   %ebp
f0102f25:	89 e5                	mov    %esp,%ebp
f0102f27:	83 ec 0c             	sub    $0xc,%esp
	asm volatile("\tmovl %0,%%esp\n"
f0102f2a:	8b 65 08             	mov    0x8(%ebp),%esp
f0102f2d:	61                   	popa   
f0102f2e:	07                   	pop    %es
f0102f2f:	1f                   	pop    %ds
f0102f30:	83 c4 08             	add    $0x8,%esp
f0102f33:	cf                   	iret   
	             "\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
	             "\tiret\n"
	             :
	             : "g"(tf)
	             : "memory");
	panic("iret failed"); /* mostly to placate the compiler */
f0102f34:	68 9b 5a 10 f0       	push   $0xf0105a9b
f0102f39:	68 ea 01 00 00       	push   $0x1ea
f0102f3e:	68 e6 59 10 f0       	push   $0xf01059e6
f0102f43:	e8 61 d1 ff ff       	call   f01000a9 <_panic>

f0102f48 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0102f48:	55                   	push   %ebp
f0102f49:	89 e5                	mov    %esp,%ebp
f0102f4b:	83 ec 08             	sub    $0x8,%esp
f0102f4e:	8b 55 08             	mov    0x8(%ebp),%edx

	// LAB 3: Your code here.
	
	//panic("env_run not yet implemented");

	if(curenv != NULL){	//si no es la primera vez que se corre esto hay que guardar todo
f0102f51:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f0102f56:	85 c0                	test   %eax,%eax
f0102f58:	74 26                	je     f0102f80 <env_run+0x38>
		assert(curenv->env_status == ENV_RUNNING);
f0102f5a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0102f5e:	74 19                	je     f0102f79 <env_run+0x31>
f0102f60:	68 c4 59 10 f0       	push   $0xf01059c4
f0102f65:	68 7a 56 10 f0       	push   $0xf010567a
f0102f6a:	68 0c 02 00 00       	push   $0x20c
f0102f6f:	68 e6 59 10 f0       	push   $0xf01059e6
f0102f74:	e8 30 d1 ff ff       	call   f01000a9 <_panic>
		if (curenv->env_status == ENV_RUNNING) curenv->env_status=ENV_RUNNABLE;
f0102f79:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
		//si FREE no tiene nada, no tiene sentido
		//si DYING ????
		//si RUNNABLE no deberia estar corriendo
		//si NOT_RUNNABLE ???
	}
	assert(e->env_status != ENV_FREE);//DEBUG2
f0102f80:	8b 42 54             	mov    0x54(%edx),%eax
f0102f83:	85 c0                	test   %eax,%eax
f0102f85:	75 19                	jne    f0102fa0 <env_run+0x58>
f0102f87:	68 a7 5a 10 f0       	push   $0xf0105aa7
f0102f8c:	68 7a 56 10 f0       	push   $0xf010567a
f0102f91:	68 14 02 00 00       	push   $0x214
f0102f96:	68 e6 59 10 f0       	push   $0xf01059e6
f0102f9b:	e8 09 d1 ff ff       	call   f01000a9 <_panic>
	assert(e->env_status == ENV_RUNNABLE);//DEBUG2
f0102fa0:	83 f8 02             	cmp    $0x2,%eax
f0102fa3:	74 19                	je     f0102fbe <env_run+0x76>
f0102fa5:	68 c1 5a 10 f0       	push   $0xf0105ac1
f0102faa:	68 7a 56 10 f0       	push   $0xf010567a
f0102faf:	68 15 02 00 00       	push   $0x215
f0102fb4:	68 e6 59 10 f0       	push   $0xf01059e6
f0102fb9:	e8 eb d0 ff ff       	call   f01000a9 <_panic>
	curenv=e;
f0102fbe:	89 15 c4 5b 19 f0    	mov    %edx,0xf0195bc4
	curenv->env_status = ENV_RUNNING;
f0102fc4:	c7 42 54 03 00 00 00 	movl   $0x3,0x54(%edx)
	curenv->env_runs++;
f0102fcb:	83 42 58 01          	addl   $0x1,0x58(%edx)
	lcr3(PADDR(curenv->env_pgdir));
f0102fcf:	8b 4a 5c             	mov    0x5c(%edx),%ecx
f0102fd2:	ba 19 02 00 00       	mov    $0x219,%edx
f0102fd7:	b8 e6 59 10 f0       	mov    $0xf01059e6,%eax
f0102fdc:	e8 ef f8 ff ff       	call   f01028d0 <_paddr>
f0102fe1:	e8 7f f8 ff ff       	call   f0102865 <lcr3>
	env_pop_tf(&(curenv->env_tf));
f0102fe6:	83 ec 0c             	sub    $0xc,%esp
f0102fe9:	ff 35 c4 5b 19 f0    	pushl  0xf0195bc4
f0102fef:	e8 30 ff ff ff       	call   f0102f24 <env_pop_tf>

f0102ff4 <inb>:
	asm volatile("int3");
}

static inline uint8_t
inb(int port)
{
f0102ff4:	55                   	push   %ebp
f0102ff5:	89 e5                	mov    %esp,%ebp
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ff7:	89 c2                	mov    %eax,%edx
f0102ff9:	ec                   	in     (%dx),%al
	return data;
}
f0102ffa:	5d                   	pop    %ebp
f0102ffb:	c3                   	ret    

f0102ffc <outb>:
		     : "memory", "cc");
}

static inline void
outb(int port, uint8_t data)
{
f0102ffc:	55                   	push   %ebp
f0102ffd:	89 e5                	mov    %esp,%ebp
f0102fff:	89 c1                	mov    %eax,%ecx
f0103001:	89 d0                	mov    %edx,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103003:	89 ca                	mov    %ecx,%edx
f0103005:	ee                   	out    %al,(%dx)
}
f0103006:	5d                   	pop    %ebp
f0103007:	c3                   	ret    

f0103008 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103008:	55                   	push   %ebp
f0103009:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010300b:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f010300f:	b8 70 00 00 00       	mov    $0x70,%eax
f0103014:	e8 e3 ff ff ff       	call   f0102ffc <outb>
	return inb(IO_RTC+1);
f0103019:	b8 71 00 00 00       	mov    $0x71,%eax
f010301e:	e8 d1 ff ff ff       	call   f0102ff4 <inb>
f0103023:	0f b6 c0             	movzbl %al,%eax
}
f0103026:	5d                   	pop    %ebp
f0103027:	c3                   	ret    

f0103028 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103028:	55                   	push   %ebp
f0103029:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
f010302b:	0f b6 55 08          	movzbl 0x8(%ebp),%edx
f010302f:	b8 70 00 00 00       	mov    $0x70,%eax
f0103034:	e8 c3 ff ff ff       	call   f0102ffc <outb>
	outb(IO_RTC+1, datum);
f0103039:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
f010303d:	b8 71 00 00 00       	mov    $0x71,%eax
f0103042:	e8 b5 ff ff ff       	call   f0102ffc <outb>
}
f0103047:	5d                   	pop    %ebp
f0103048:	c3                   	ret    

f0103049 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103049:	55                   	push   %ebp
f010304a:	89 e5                	mov    %esp,%ebp
f010304c:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f010304f:	ff 75 08             	pushl  0x8(%ebp)
f0103052:	e8 cc d6 ff ff       	call   f0100723 <cputchar>
	*cnt++;
}
f0103057:	83 c4 10             	add    $0x10,%esp
f010305a:	c9                   	leave  
f010305b:	c3                   	ret    

f010305c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010305c:	55                   	push   %ebp
f010305d:	89 e5                	mov    %esp,%ebp
f010305f:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103062:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103069:	ff 75 0c             	pushl  0xc(%ebp)
f010306c:	ff 75 08             	pushl  0x8(%ebp)
f010306f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103072:	50                   	push   %eax
f0103073:	68 49 30 10 f0       	push   $0xf0103049
f0103078:	e8 e5 0d 00 00       	call   f0103e62 <vprintfmt>
	return cnt;
}
f010307d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103080:	c9                   	leave  
f0103081:	c3                   	ret    

f0103082 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103082:	55                   	push   %ebp
f0103083:	89 e5                	mov    %esp,%ebp
f0103085:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103088:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010308b:	50                   	push   %eax
f010308c:	ff 75 08             	pushl  0x8(%ebp)
f010308f:	e8 c8 ff ff ff       	call   f010305c <vcprintf>
	va_end(ap);

	return cnt;
}
f0103094:	c9                   	leave  
f0103095:	c3                   	ret    

f0103096 <lidt>:
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
}

static inline void
lidt(void *p)
{
f0103096:	55                   	push   %ebp
f0103097:	89 e5                	mov    %esp,%ebp
	asm volatile("lidt (%0)" : : "r" (p));
f0103099:	0f 01 18             	lidtl  (%eax)
}
f010309c:	5d                   	pop    %ebp
f010309d:	c3                   	ret    

f010309e <ltr>:
	asm volatile("lldt %0" : : "r" (sel));
}

static inline void
ltr(uint16_t sel)
{
f010309e:	55                   	push   %ebp
f010309f:	89 e5                	mov    %esp,%ebp
	asm volatile("ltr %0" : : "r" (sel));
f01030a1:	0f 00 d8             	ltr    %ax
}
f01030a4:	5d                   	pop    %ebp
f01030a5:	c3                   	ret    

f01030a6 <rcr2>:
	return val;
}

static inline uint32_t
rcr2(void)
{
f01030a6:	55                   	push   %ebp
f01030a7:	89 e5                	mov    %esp,%ebp
	uint32_t val;
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01030a9:	0f 20 d0             	mov    %cr2,%eax
	return val;
}
f01030ac:	5d                   	pop    %ebp
f01030ad:	c3                   	ret    

f01030ae <read_eflags>:
	asm volatile("movl %0,%%cr3" : : "r" (cr3));
}

static inline uint32_t
read_eflags(void)
{
f01030ae:	55                   	push   %ebp
f01030af:	89 e5                	mov    %esp,%ebp
	uint32_t eflags;
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01030b1:	9c                   	pushf  
f01030b2:	58                   	pop    %eax
	return eflags;
}
f01030b3:	5d                   	pop    %ebp
f01030b4:	c3                   	ret    

f01030b5 <trapname>:
struct Pseudodesc idt_pd = { sizeof(idt) - 1, (uint32_t) idt };


static const char *
trapname(int trapno)
{
f01030b5:	55                   	push   %ebp
f01030b6:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < ARRAY_SIZE(excnames))
f01030b8:	83 f8 13             	cmp    $0x13,%eax
f01030bb:	77 09                	ja     f01030c6 <trapname+0x11>
		return excnames[trapno];
f01030bd:	8b 04 85 a0 5e 10 f0 	mov    -0xfefa160(,%eax,4),%eax
f01030c4:	eb 10                	jmp    f01030d6 <trapname+0x21>
	if (trapno == T_SYSCALL)
f01030c6:	83 f8 30             	cmp    $0x30,%eax
		return "System call";
	return "(unknown trap)";
f01030c9:	ba eb 5a 10 f0       	mov    $0xf0105aeb,%edx
f01030ce:	b8 df 5a 10 f0       	mov    $0xf0105adf,%eax
f01030d3:	0f 45 c2             	cmovne %edx,%eax
}
f01030d6:	5d                   	pop    %ebp
f01030d7:	c3                   	ret    

f01030d8 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01030d8:	55                   	push   %ebp
f01030d9:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01030db:	b8 00 64 19 f0       	mov    $0xf0196400,%eax
f01030e0:	c7 05 04 64 19 f0 00 	movl   $0xf0000000,0xf0196404
f01030e7:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01030ea:	66 c7 05 08 64 19 f0 	movw   $0x10,0xf0196408
f01030f1:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] =
f01030f3:	66 c7 05 48 03 11 f0 	movw   $0x67,0xf0110348
f01030fa:	67 00 
f01030fc:	66 a3 4a 03 11 f0    	mov    %ax,0xf011034a
f0103102:	89 c2                	mov    %eax,%edx
f0103104:	c1 ea 10             	shr    $0x10,%edx
f0103107:	88 15 4c 03 11 f0    	mov    %dl,0xf011034c
f010310d:	c6 05 4e 03 11 f0 40 	movb   $0x40,0xf011034e
f0103114:	c1 e8 18             	shr    $0x18,%eax
f0103117:	a2 4f 03 11 f0       	mov    %al,0xf011034f
	        SEG16(STS_T32A, (uint32_t)(&ts), sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010311c:	c6 05 4d 03 11 f0 89 	movb   $0x89,0xf011034d

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
f0103123:	b8 28 00 00 00       	mov    $0x28,%eax
f0103128:	e8 71 ff ff ff       	call   f010309e <ltr>

	// Load the IDT
	lidt(&idt_pd);
f010312d:	b8 50 03 11 f0       	mov    $0xf0110350,%eax
f0103132:	e8 5f ff ff ff       	call   f0103096 <lidt>
}
f0103137:	5d                   	pop    %ebp
f0103138:	c3                   	ret    

f0103139 <trap_init>:
void Trap_48();


void
trap_init(void)
{
f0103139:	55                   	push   %ebp
f010313a:	89 e5                	mov    %esp,%ebp
f010313c:	83 ec 14             	sub    $0x14,%esp
	cprintf("Se setean los gates \n");
f010313f:	68 fa 5a 10 f0       	push   $0xf0105afa
f0103144:	e8 39 ff ff ff       	call   f0103082 <cprintf>
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.
	SETGATE(idt[0], 1, GD_KT, Trap_0, 0);
f0103149:	b8 2e 38 10 f0       	mov    $0xf010382e,%eax
f010314e:	66 a3 e0 5b 19 f0    	mov    %ax,0xf0195be0
f0103154:	66 c7 05 e2 5b 19 f0 	movw   $0x8,0xf0195be2
f010315b:	08 00 
f010315d:	c6 05 e4 5b 19 f0 00 	movb   $0x0,0xf0195be4
f0103164:	c6 05 e5 5b 19 f0 8f 	movb   $0x8f,0xf0195be5
f010316b:	c1 e8 10             	shr    $0x10,%eax
f010316e:	66 a3 e6 5b 19 f0    	mov    %ax,0xf0195be6
	SETGATE(idt[1], 1, GD_KT, Trap_1, 0);
f0103174:	b8 34 38 10 f0       	mov    $0xf0103834,%eax
f0103179:	66 a3 e8 5b 19 f0    	mov    %ax,0xf0195be8
f010317f:	66 c7 05 ea 5b 19 f0 	movw   $0x8,0xf0195bea
f0103186:	08 00 
f0103188:	c6 05 ec 5b 19 f0 00 	movb   $0x0,0xf0195bec
f010318f:	c6 05 ed 5b 19 f0 8f 	movb   $0x8f,0xf0195bed
f0103196:	c1 e8 10             	shr    $0x10,%eax
f0103199:	66 a3 ee 5b 19 f0    	mov    %ax,0xf0195bee
	SETGATE(idt[2], 1, GD_KT, Trap_2, 0); 
f010319f:	b8 3a 38 10 f0       	mov    $0xf010383a,%eax
f01031a4:	66 a3 f0 5b 19 f0    	mov    %ax,0xf0195bf0
f01031aa:	66 c7 05 f2 5b 19 f0 	movw   $0x8,0xf0195bf2
f01031b1:	08 00 
f01031b3:	c6 05 f4 5b 19 f0 00 	movb   $0x0,0xf0195bf4
f01031ba:	c6 05 f5 5b 19 f0 8f 	movb   $0x8f,0xf0195bf5
f01031c1:	c1 e8 10             	shr    $0x10,%eax
f01031c4:	66 a3 f6 5b 19 f0    	mov    %ax,0xf0195bf6
	SETGATE(idt[3], 0, GD_KT, Trap_3, 3);
f01031ca:	b8 40 38 10 f0       	mov    $0xf0103840,%eax
f01031cf:	66 a3 f8 5b 19 f0    	mov    %ax,0xf0195bf8
f01031d5:	66 c7 05 fa 5b 19 f0 	movw   $0x8,0xf0195bfa
f01031dc:	08 00 
f01031de:	c6 05 fc 5b 19 f0 00 	movb   $0x0,0xf0195bfc
f01031e5:	c6 05 fd 5b 19 f0 ee 	movb   $0xee,0xf0195bfd
f01031ec:	c1 e8 10             	shr    $0x10,%eax
f01031ef:	66 a3 fe 5b 19 f0    	mov    %ax,0xf0195bfe
	SETGATE(idt[4], 1, GD_KT, Trap_4, 0);
f01031f5:	b8 46 38 10 f0       	mov    $0xf0103846,%eax
f01031fa:	66 a3 00 5c 19 f0    	mov    %ax,0xf0195c00
f0103200:	66 c7 05 02 5c 19 f0 	movw   $0x8,0xf0195c02
f0103207:	08 00 
f0103209:	c6 05 04 5c 19 f0 00 	movb   $0x0,0xf0195c04
f0103210:	c6 05 05 5c 19 f0 8f 	movb   $0x8f,0xf0195c05
f0103217:	c1 e8 10             	shr    $0x10,%eax
f010321a:	66 a3 06 5c 19 f0    	mov    %ax,0xf0195c06
	SETGATE(idt[5], 1, GD_KT, Trap_5, 0);
f0103220:	b8 4c 38 10 f0       	mov    $0xf010384c,%eax
f0103225:	66 a3 08 5c 19 f0    	mov    %ax,0xf0195c08
f010322b:	66 c7 05 0a 5c 19 f0 	movw   $0x8,0xf0195c0a
f0103232:	08 00 
f0103234:	c6 05 0c 5c 19 f0 00 	movb   $0x0,0xf0195c0c
f010323b:	c6 05 0d 5c 19 f0 8f 	movb   $0x8f,0xf0195c0d
f0103242:	c1 e8 10             	shr    $0x10,%eax
f0103245:	66 a3 0e 5c 19 f0    	mov    %ax,0xf0195c0e
	SETGATE(idt[6], 1, GD_KT, Trap_6, 0);
f010324b:	b8 52 38 10 f0       	mov    $0xf0103852,%eax
f0103250:	66 a3 10 5c 19 f0    	mov    %ax,0xf0195c10
f0103256:	66 c7 05 12 5c 19 f0 	movw   $0x8,0xf0195c12
f010325d:	08 00 
f010325f:	c6 05 14 5c 19 f0 00 	movb   $0x0,0xf0195c14
f0103266:	c6 05 15 5c 19 f0 8f 	movb   $0x8f,0xf0195c15
f010326d:	c1 e8 10             	shr    $0x10,%eax
f0103270:	66 a3 16 5c 19 f0    	mov    %ax,0xf0195c16
	SETGATE(idt[7], 1, GD_KT, Trap_7, 0);
f0103276:	b8 58 38 10 f0       	mov    $0xf0103858,%eax
f010327b:	66 a3 18 5c 19 f0    	mov    %ax,0xf0195c18
f0103281:	66 c7 05 1a 5c 19 f0 	movw   $0x8,0xf0195c1a
f0103288:	08 00 
f010328a:	c6 05 1c 5c 19 f0 00 	movb   $0x0,0xf0195c1c
f0103291:	c6 05 1d 5c 19 f0 8f 	movb   $0x8f,0xf0195c1d
f0103298:	c1 e8 10             	shr    $0x10,%eax
f010329b:	66 a3 1e 5c 19 f0    	mov    %ax,0xf0195c1e
	SETGATE(idt[8], 1, GD_KT, Trap_8, 0); 
f01032a1:	b8 5e 38 10 f0       	mov    $0xf010385e,%eax
f01032a6:	66 a3 20 5c 19 f0    	mov    %ax,0xf0195c20
f01032ac:	66 c7 05 22 5c 19 f0 	movw   $0x8,0xf0195c22
f01032b3:	08 00 
f01032b5:	c6 05 24 5c 19 f0 00 	movb   $0x0,0xf0195c24
f01032bc:	c6 05 25 5c 19 f0 8f 	movb   $0x8f,0xf0195c25
f01032c3:	c1 e8 10             	shr    $0x10,%eax
f01032c6:	66 a3 26 5c 19 f0    	mov    %ax,0xf0195c26
	SETGATE(idt[10], 1, GD_KT, Trap_10, 0); 
f01032cc:	b8 62 38 10 f0       	mov    $0xf0103862,%eax
f01032d1:	66 a3 30 5c 19 f0    	mov    %ax,0xf0195c30
f01032d7:	66 c7 05 32 5c 19 f0 	movw   $0x8,0xf0195c32
f01032de:	08 00 
f01032e0:	c6 05 34 5c 19 f0 00 	movb   $0x0,0xf0195c34
f01032e7:	c6 05 35 5c 19 f0 8f 	movb   $0x8f,0xf0195c35
f01032ee:	c1 e8 10             	shr    $0x10,%eax
f01032f1:	66 a3 36 5c 19 f0    	mov    %ax,0xf0195c36
	SETGATE(idt[11], 1, GD_KT, Trap_11, 0); 
f01032f7:	b8 66 38 10 f0       	mov    $0xf0103866,%eax
f01032fc:	66 a3 38 5c 19 f0    	mov    %ax,0xf0195c38
f0103302:	66 c7 05 3a 5c 19 f0 	movw   $0x8,0xf0195c3a
f0103309:	08 00 
f010330b:	c6 05 3c 5c 19 f0 00 	movb   $0x0,0xf0195c3c
f0103312:	c6 05 3d 5c 19 f0 8f 	movb   $0x8f,0xf0195c3d
f0103319:	c1 e8 10             	shr    $0x10,%eax
f010331c:	66 a3 3e 5c 19 f0    	mov    %ax,0xf0195c3e
	SETGATE(idt[12], 1, GD_KT, Trap_12, 0); 
f0103322:	b8 6a 38 10 f0       	mov    $0xf010386a,%eax
f0103327:	66 a3 40 5c 19 f0    	mov    %ax,0xf0195c40
f010332d:	66 c7 05 42 5c 19 f0 	movw   $0x8,0xf0195c42
f0103334:	08 00 
f0103336:	c6 05 44 5c 19 f0 00 	movb   $0x0,0xf0195c44
f010333d:	c6 05 45 5c 19 f0 8f 	movb   $0x8f,0xf0195c45
f0103344:	c1 e8 10             	shr    $0x10,%eax
f0103347:	66 a3 46 5c 19 f0    	mov    %ax,0xf0195c46
	SETGATE(idt[13], 1, GD_KT, Trap_13, 0); 
f010334d:	b8 6e 38 10 f0       	mov    $0xf010386e,%eax
f0103352:	66 a3 48 5c 19 f0    	mov    %ax,0xf0195c48
f0103358:	66 c7 05 4a 5c 19 f0 	movw   $0x8,0xf0195c4a
f010335f:	08 00 
f0103361:	c6 05 4c 5c 19 f0 00 	movb   $0x0,0xf0195c4c
f0103368:	c6 05 4d 5c 19 f0 8f 	movb   $0x8f,0xf0195c4d
f010336f:	c1 e8 10             	shr    $0x10,%eax
f0103372:	66 a3 4e 5c 19 f0    	mov    %ax,0xf0195c4e
	SETGATE(idt[14], 1, GD_KT, Trap_14, 0); 
f0103378:	b8 72 38 10 f0       	mov    $0xf0103872,%eax
f010337d:	66 a3 50 5c 19 f0    	mov    %ax,0xf0195c50
f0103383:	66 c7 05 52 5c 19 f0 	movw   $0x8,0xf0195c52
f010338a:	08 00 
f010338c:	c6 05 54 5c 19 f0 00 	movb   $0x0,0xf0195c54
f0103393:	c6 05 55 5c 19 f0 8f 	movb   $0x8f,0xf0195c55
f010339a:	c1 e8 10             	shr    $0x10,%eax
f010339d:	66 a3 56 5c 19 f0    	mov    %ax,0xf0195c56
	SETGATE(idt[16], 1, GD_KT, Trap_16, 0);
f01033a3:	b8 76 38 10 f0       	mov    $0xf0103876,%eax
f01033a8:	66 a3 60 5c 19 f0    	mov    %ax,0xf0195c60
f01033ae:	66 c7 05 62 5c 19 f0 	movw   $0x8,0xf0195c62
f01033b5:	08 00 
f01033b7:	c6 05 64 5c 19 f0 00 	movb   $0x0,0xf0195c64
f01033be:	c6 05 65 5c 19 f0 8f 	movb   $0x8f,0xf0195c65
f01033c5:	c1 e8 10             	shr    $0x10,%eax
f01033c8:	66 a3 66 5c 19 f0    	mov    %ax,0xf0195c66
	SETGATE(idt[17], 1, GD_KT, Trap_17, 0); 
f01033ce:	b8 7c 38 10 f0       	mov    $0xf010387c,%eax
f01033d3:	66 a3 68 5c 19 f0    	mov    %ax,0xf0195c68
f01033d9:	66 c7 05 6a 5c 19 f0 	movw   $0x8,0xf0195c6a
f01033e0:	08 00 
f01033e2:	c6 05 6c 5c 19 f0 00 	movb   $0x0,0xf0195c6c
f01033e9:	c6 05 6d 5c 19 f0 8f 	movb   $0x8f,0xf0195c6d
f01033f0:	c1 e8 10             	shr    $0x10,%eax
f01033f3:	66 a3 6e 5c 19 f0    	mov    %ax,0xf0195c6e
	SETGATE(idt[18], 1, GD_KT, Trap_18, 0); 
f01033f9:	b8 80 38 10 f0       	mov    $0xf0103880,%eax
f01033fe:	66 a3 70 5c 19 f0    	mov    %ax,0xf0195c70
f0103404:	66 c7 05 72 5c 19 f0 	movw   $0x8,0xf0195c72
f010340b:	08 00 
f010340d:	c6 05 74 5c 19 f0 00 	movb   $0x0,0xf0195c74
f0103414:	c6 05 75 5c 19 f0 8f 	movb   $0x8f,0xf0195c75
f010341b:	c1 e8 10             	shr    $0x10,%eax
f010341e:	66 a3 76 5c 19 f0    	mov    %ax,0xf0195c76
	SETGATE(idt[19], 1, GD_KT, Trap_19, 0); 
f0103424:	b8 86 38 10 f0       	mov    $0xf0103886,%eax
f0103429:	66 a3 78 5c 19 f0    	mov    %ax,0xf0195c78
f010342f:	66 c7 05 7a 5c 19 f0 	movw   $0x8,0xf0195c7a
f0103436:	08 00 
f0103438:	c6 05 7c 5c 19 f0 00 	movb   $0x0,0xf0195c7c
f010343f:	c6 05 7d 5c 19 f0 8f 	movb   $0x8f,0xf0195c7d
f0103446:	c1 e8 10             	shr    $0x10,%eax
f0103449:	66 a3 7e 5c 19 f0    	mov    %ax,0xf0195c7e
	SETGATE(idt[48], 0, GD_KT, Trap_48, 3);
f010344f:	b8 8c 38 10 f0       	mov    $0xf010388c,%eax
f0103454:	66 a3 60 5d 19 f0    	mov    %ax,0xf0195d60
f010345a:	66 c7 05 62 5d 19 f0 	movw   $0x8,0xf0195d62
f0103461:	08 00 
f0103463:	c6 05 64 5d 19 f0 00 	movb   $0x0,0xf0195d64
f010346a:	c6 05 65 5d 19 f0 ee 	movb   $0xee,0xf0195d65
f0103471:	c1 e8 10             	shr    $0x10,%eax
f0103474:	66 a3 66 5d 19 f0    	mov    %ax,0xf0195d66

	cprintf("Se setearon los gates\n");
f010347a:	c7 04 24 10 5b 10 f0 	movl   $0xf0105b10,(%esp)
f0103481:	e8 fc fb ff ff       	call   f0103082 <cprintf>

	// Per-CPU setup
	trap_init_percpu();
f0103486:	e8 4d fc ff ff       	call   f01030d8 <trap_init_percpu>
}
f010348b:	83 c4 10             	add    $0x10,%esp
f010348e:	c9                   	leave  
f010348f:	c3                   	ret    

f0103490 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103490:	55                   	push   %ebp
f0103491:	89 e5                	mov    %esp,%ebp
f0103493:	53                   	push   %ebx
f0103494:	83 ec 0c             	sub    $0xc,%esp
f0103497:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010349a:	ff 33                	pushl  (%ebx)
f010349c:	68 27 5b 10 f0       	push   $0xf0105b27
f01034a1:	e8 dc fb ff ff       	call   f0103082 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01034a6:	83 c4 08             	add    $0x8,%esp
f01034a9:	ff 73 04             	pushl  0x4(%ebx)
f01034ac:	68 36 5b 10 f0       	push   $0xf0105b36
f01034b1:	e8 cc fb ff ff       	call   f0103082 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01034b6:	83 c4 08             	add    $0x8,%esp
f01034b9:	ff 73 08             	pushl  0x8(%ebx)
f01034bc:	68 45 5b 10 f0       	push   $0xf0105b45
f01034c1:	e8 bc fb ff ff       	call   f0103082 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01034c6:	83 c4 08             	add    $0x8,%esp
f01034c9:	ff 73 0c             	pushl  0xc(%ebx)
f01034cc:	68 54 5b 10 f0       	push   $0xf0105b54
f01034d1:	e8 ac fb ff ff       	call   f0103082 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01034d6:	83 c4 08             	add    $0x8,%esp
f01034d9:	ff 73 10             	pushl  0x10(%ebx)
f01034dc:	68 63 5b 10 f0       	push   $0xf0105b63
f01034e1:	e8 9c fb ff ff       	call   f0103082 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01034e6:	83 c4 08             	add    $0x8,%esp
f01034e9:	ff 73 14             	pushl  0x14(%ebx)
f01034ec:	68 72 5b 10 f0       	push   $0xf0105b72
f01034f1:	e8 8c fb ff ff       	call   f0103082 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01034f6:	83 c4 08             	add    $0x8,%esp
f01034f9:	ff 73 18             	pushl  0x18(%ebx)
f01034fc:	68 81 5b 10 f0       	push   $0xf0105b81
f0103501:	e8 7c fb ff ff       	call   f0103082 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103506:	83 c4 08             	add    $0x8,%esp
f0103509:	ff 73 1c             	pushl  0x1c(%ebx)
f010350c:	68 90 5b 10 f0       	push   $0xf0105b90
f0103511:	e8 6c fb ff ff       	call   f0103082 <cprintf>
}
f0103516:	83 c4 10             	add    $0x10,%esp
f0103519:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010351c:	c9                   	leave  
f010351d:	c3                   	ret    

f010351e <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f010351e:	55                   	push   %ebp
f010351f:	89 e5                	mov    %esp,%ebp
f0103521:	56                   	push   %esi
f0103522:	53                   	push   %ebx
f0103523:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103526:	83 ec 08             	sub    $0x8,%esp
f0103529:	53                   	push   %ebx
f010352a:	68 c4 5c 10 f0       	push   $0xf0105cc4
f010352f:	e8 4e fb ff ff       	call   f0103082 <cprintf>
	print_regs(&tf->tf_regs);
f0103534:	89 1c 24             	mov    %ebx,(%esp)
f0103537:	e8 54 ff ff ff       	call   f0103490 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010353c:	83 c4 08             	add    $0x8,%esp
f010353f:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103543:	50                   	push   %eax
f0103544:	68 c6 5b 10 f0       	push   $0xf0105bc6
f0103549:	e8 34 fb ff ff       	call   f0103082 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010354e:	83 c4 08             	add    $0x8,%esp
f0103551:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103555:	50                   	push   %eax
f0103556:	68 d9 5b 10 f0       	push   $0xf0105bd9
f010355b:	e8 22 fb ff ff       	call   f0103082 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103560:	8b 73 28             	mov    0x28(%ebx),%esi
f0103563:	89 f0                	mov    %esi,%eax
f0103565:	e8 4b fb ff ff       	call   f01030b5 <trapname>
f010356a:	83 c4 0c             	add    $0xc,%esp
f010356d:	50                   	push   %eax
f010356e:	56                   	push   %esi
f010356f:	68 ec 5b 10 f0       	push   $0xf0105bec
f0103574:	e8 09 fb ff ff       	call   f0103082 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103579:	83 c4 10             	add    $0x10,%esp
f010357c:	3b 1d e0 63 19 f0    	cmp    0xf01963e0,%ebx
f0103582:	75 1c                	jne    f01035a0 <print_trapframe+0x82>
f0103584:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103588:	75 16                	jne    f01035a0 <print_trapframe+0x82>
		cprintf("  cr2  0x%08x\n", rcr2());
f010358a:	e8 17 fb ff ff       	call   f01030a6 <rcr2>
f010358f:	83 ec 08             	sub    $0x8,%esp
f0103592:	50                   	push   %eax
f0103593:	68 fe 5b 10 f0       	push   $0xf0105bfe
f0103598:	e8 e5 fa ff ff       	call   f0103082 <cprintf>
f010359d:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f01035a0:	83 ec 08             	sub    $0x8,%esp
f01035a3:	ff 73 2c             	pushl  0x2c(%ebx)
f01035a6:	68 0d 5c 10 f0       	push   $0xf0105c0d
f01035ab:	e8 d2 fa ff ff       	call   f0103082 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01035b0:	83 c4 10             	add    $0x10,%esp
f01035b3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01035b7:	75 49                	jne    f0103602 <print_trapframe+0xe4>
		cprintf(" [%s, %s, %s]\n",
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
f01035b9:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01035bc:	89 c2                	mov    %eax,%edx
f01035be:	83 e2 01             	and    $0x1,%edx
f01035c1:	ba aa 5b 10 f0       	mov    $0xf0105baa,%edx
f01035c6:	b9 9f 5b 10 f0       	mov    $0xf0105b9f,%ecx
f01035cb:	0f 44 ca             	cmove  %edx,%ecx
f01035ce:	89 c2                	mov    %eax,%edx
f01035d0:	83 e2 02             	and    $0x2,%edx
f01035d3:	ba bc 5b 10 f0       	mov    $0xf0105bbc,%edx
f01035d8:	be b6 5b 10 f0       	mov    $0xf0105bb6,%esi
f01035dd:	0f 45 d6             	cmovne %esi,%edx
f01035e0:	83 e0 04             	and    $0x4,%eax
f01035e3:	be 9b 5c 10 f0       	mov    $0xf0105c9b,%esi
f01035e8:	b8 c1 5b 10 f0       	mov    $0xf0105bc1,%eax
f01035ed:	0f 44 c6             	cmove  %esi,%eax
f01035f0:	51                   	push   %ecx
f01035f1:	52                   	push   %edx
f01035f2:	50                   	push   %eax
f01035f3:	68 1b 5c 10 f0       	push   $0xf0105c1b
f01035f8:	e8 85 fa ff ff       	call   f0103082 <cprintf>
f01035fd:	83 c4 10             	add    $0x10,%esp
f0103600:	eb 10                	jmp    f0103612 <print_trapframe+0xf4>
		        tf->tf_err & 4 ? "user" : "kernel",
		        tf->tf_err & 2 ? "write" : "read",
		        tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103602:	83 ec 0c             	sub    $0xc,%esp
f0103605:	68 0e 5b 10 f0       	push   $0xf0105b0e
f010360a:	e8 73 fa ff ff       	call   f0103082 <cprintf>
f010360f:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103612:	83 ec 08             	sub    $0x8,%esp
f0103615:	ff 73 30             	pushl  0x30(%ebx)
f0103618:	68 2a 5c 10 f0       	push   $0xf0105c2a
f010361d:	e8 60 fa ff ff       	call   f0103082 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103622:	83 c4 08             	add    $0x8,%esp
f0103625:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103629:	50                   	push   %eax
f010362a:	68 39 5c 10 f0       	push   $0xf0105c39
f010362f:	e8 4e fa ff ff       	call   f0103082 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103634:	83 c4 08             	add    $0x8,%esp
f0103637:	ff 73 38             	pushl  0x38(%ebx)
f010363a:	68 4c 5c 10 f0       	push   $0xf0105c4c
f010363f:	e8 3e fa ff ff       	call   f0103082 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103644:	83 c4 10             	add    $0x10,%esp
f0103647:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010364b:	74 25                	je     f0103672 <print_trapframe+0x154>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010364d:	83 ec 08             	sub    $0x8,%esp
f0103650:	ff 73 3c             	pushl  0x3c(%ebx)
f0103653:	68 5b 5c 10 f0       	push   $0xf0105c5b
f0103658:	e8 25 fa ff ff       	call   f0103082 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010365d:	83 c4 08             	add    $0x8,%esp
f0103660:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103664:	50                   	push   %eax
f0103665:	68 6a 5c 10 f0       	push   $0xf0105c6a
f010366a:	e8 13 fa ff ff       	call   f0103082 <cprintf>
f010366f:	83 c4 10             	add    $0x10,%esp
	}
}
f0103672:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103675:	5b                   	pop    %ebx
f0103676:	5e                   	pop    %esi
f0103677:	5d                   	pop    %ebp
f0103678:	c3                   	ret    

f0103679 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103679:	55                   	push   %ebp
f010367a:	89 e5                	mov    %esp,%ebp
f010367c:	53                   	push   %ebx
f010367d:	83 ec 04             	sub    $0x4,%esp
f0103680:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();
f0103683:	e8 1e fa ff ff       	call   f01030a6 <rcr2>

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	if (!(tf->tf_cs & 0x3)) { //si CPL==0 es ring0 aka kernel
f0103688:	0f b7 53 34          	movzwl 0x34(%ebx),%edx
f010368c:	f6 c2 03             	test   $0x3,%dl
f010368f:	75 18                	jne    f01036a9 <page_fault_handler+0x30>
		panic("Kernel-mode page fault!!tf_cs=%p",tf->tf_cs);
f0103691:	0f b7 d2             	movzwl %dx,%edx
f0103694:	52                   	push   %edx
f0103695:	68 20 5e 10 f0       	push   $0xf0105e20
f010369a:	68 0b 01 00 00       	push   $0x10b
f010369f:	68 7d 5c 10 f0       	push   $0xf0105c7d
f01036a4:	e8 00 ca ff ff       	call   f01000a9 <_panic>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01036a9:	ff 73 30             	pushl  0x30(%ebx)
f01036ac:	50                   	push   %eax
f01036ad:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f01036b2:	ff 70 48             	pushl  0x48(%eax)
f01036b5:	68 44 5e 10 f0       	push   $0xf0105e44
f01036ba:	e8 c3 f9 ff ff       	call   f0103082 <cprintf>
	        curenv->env_id,
	        fault_va,
	        tf->tf_eip);
	print_trapframe(tf);
f01036bf:	89 1c 24             	mov    %ebx,(%esp)
f01036c2:	e8 57 fe ff ff       	call   f010351e <print_trapframe>
	env_destroy(curenv);
f01036c7:	83 c4 04             	add    $0x4,%esp
f01036ca:	ff 35 c4 5b 19 f0    	pushl  0xf0195bc4
f01036d0:	e8 23 f8 ff ff       	call   f0102ef8 <env_destroy>
}
f01036d5:	83 c4 10             	add    $0x10,%esp
f01036d8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01036db:	c9                   	leave  
f01036dc:	c3                   	ret    

f01036dd <trap_dispatch>:
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
f01036dd:	55                   	push   %ebp
f01036de:	89 e5                	mov    %esp,%ebp
f01036e0:	53                   	push   %ebx
f01036e1:	83 ec 04             	sub    $0x4,%esp
f01036e4:	89 c3                	mov    %eax,%ebx
	// Handle processor exceptions.
	// LAB 3: Your code here.
	if(tf->tf_trapno == T_BRKPT){
f01036e6:	8b 40 28             	mov    0x28(%eax),%eax
f01036e9:	83 f8 03             	cmp    $0x3,%eax
f01036ec:	75 0e                	jne    f01036fc <trap_dispatch+0x1f>
		monitor(tf);	
f01036ee:	83 ec 0c             	sub    $0xc,%esp
f01036f1:	53                   	push   %ebx
f01036f2:	e8 cf d2 ff ff       	call   f01009c6 <monitor>
		return;
f01036f7:	83 c4 10             	add    $0x10,%esp
f01036fa:	eb 74                	jmp    f0103770 <trap_dispatch+0x93>
	}
	if(tf->tf_trapno == T_PGFLT){
f01036fc:	83 f8 0e             	cmp    $0xe,%eax
f01036ff:	75 0e                	jne    f010370f <trap_dispatch+0x32>
		page_fault_handler(tf);
f0103701:	83 ec 0c             	sub    $0xc,%esp
f0103704:	53                   	push   %ebx
f0103705:	e8 6f ff ff ff       	call   f0103679 <page_fault_handler>
		return;
f010370a:	83 c4 10             	add    $0x10,%esp
f010370d:	eb 61                	jmp    f0103770 <trap_dispatch+0x93>
	}
	if(tf->tf_trapno == T_SYSCALL){
f010370f:	83 f8 30             	cmp    $0x30,%eax
f0103712:	75 21                	jne    f0103735 <trap_dispatch+0x58>
		uint32_t resultado = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
f0103714:	83 ec 08             	sub    $0x8,%esp
f0103717:	ff 73 04             	pushl  0x4(%ebx)
f010371a:	ff 33                	pushl  (%ebx)
f010371c:	ff 73 10             	pushl  0x10(%ebx)
f010371f:	ff 73 18             	pushl  0x18(%ebx)
f0103722:	ff 73 14             	pushl  0x14(%ebx)
f0103725:	ff 73 1c             	pushl  0x1c(%ebx)
f0103728:	e8 51 02 00 00       	call   f010397e <syscall>

		//guardar resultado en eax;
		tf->tf_regs.reg_eax = resultado;
f010372d:	89 43 1c             	mov    %eax,0x1c(%ebx)
		return;
f0103730:	83 c4 20             	add    $0x20,%esp
f0103733:	eb 3b                	jmp    f0103770 <trap_dispatch+0x93>
	}


	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103735:	83 ec 0c             	sub    $0xc,%esp
f0103738:	53                   	push   %ebx
f0103739:	e8 e0 fd ff ff       	call   f010351e <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010373e:	83 c4 10             	add    $0x10,%esp
f0103741:	66 83 7b 34 08       	cmpw   $0x8,0x34(%ebx)
f0103746:	75 17                	jne    f010375f <trap_dispatch+0x82>
		panic("unhandled trap in kernel");
f0103748:	83 ec 04             	sub    $0x4,%esp
f010374b:	68 89 5c 10 f0       	push   $0xf0105c89
f0103750:	68 d0 00 00 00       	push   $0xd0
f0103755:	68 7d 5c 10 f0       	push   $0xf0105c7d
f010375a:	e8 4a c9 ff ff       	call   f01000a9 <_panic>
	else {
		env_destroy(curenv);
f010375f:	83 ec 0c             	sub    $0xc,%esp
f0103762:	ff 35 c4 5b 19 f0    	pushl  0xf0195bc4
f0103768:	e8 8b f7 ff ff       	call   f0102ef8 <env_destroy>
		return;
f010376d:	83 c4 10             	add    $0x10,%esp
	}
}
f0103770:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103773:	c9                   	leave  
f0103774:	c3                   	ret    

f0103775 <trap>:

void
trap(struct Trapframe *tf)
{
f0103775:	55                   	push   %ebp
f0103776:	89 e5                	mov    %esp,%ebp
f0103778:	57                   	push   %edi
f0103779:	56                   	push   %esi
f010377a:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010377d:	fc                   	cld    

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f010377e:	e8 2b f9 ff ff       	call   f01030ae <read_eflags>
f0103783:	f6 c4 02             	test   $0x2,%ah
f0103786:	74 19                	je     f01037a1 <trap+0x2c>
f0103788:	68 a2 5c 10 f0       	push   $0xf0105ca2
f010378d:	68 7a 56 10 f0       	push   $0xf010567a
f0103792:	68 e1 00 00 00       	push   $0xe1
f0103797:	68 7d 5c 10 f0       	push   $0xf0105c7d
f010379c:	e8 08 c9 ff ff       	call   f01000a9 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01037a1:	83 ec 08             	sub    $0x8,%esp
f01037a4:	56                   	push   %esi
f01037a5:	68 bb 5c 10 f0       	push   $0xf0105cbb
f01037aa:	e8 d3 f8 ff ff       	call   f0103082 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01037af:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01037b3:	83 e0 03             	and    $0x3,%eax
f01037b6:	83 c4 10             	add    $0x10,%esp
f01037b9:	66 83 f8 03          	cmp    $0x3,%ax
f01037bd:	75 31                	jne    f01037f0 <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f01037bf:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f01037c4:	85 c0                	test   %eax,%eax
f01037c6:	75 19                	jne    f01037e1 <trap+0x6c>
f01037c8:	68 d6 5c 10 f0       	push   $0xf0105cd6
f01037cd:	68 7a 56 10 f0       	push   $0xf010567a
f01037d2:	68 e7 00 00 00       	push   $0xe7
f01037d7:	68 7d 5c 10 f0       	push   $0xf0105c7d
f01037dc:	e8 c8 c8 ff ff       	call   f01000a9 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01037e1:	b9 11 00 00 00       	mov    $0x11,%ecx
f01037e6:	89 c7                	mov    %eax,%edi
f01037e8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01037ea:	8b 35 c4 5b 19 f0    	mov    0xf0195bc4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f01037f0:	89 35 e0 63 19 f0    	mov    %esi,0xf01963e0

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);
f01037f6:	89 f0                	mov    %esi,%eax
f01037f8:	e8 e0 fe ff ff       	call   f01036dd <trap_dispatch>

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01037fd:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f0103802:	85 c0                	test   %eax,%eax
f0103804:	74 06                	je     f010380c <trap+0x97>
f0103806:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010380a:	74 19                	je     f0103825 <trap+0xb0>
f010380c:	68 68 5e 10 f0       	push   $0xf0105e68
f0103811:	68 7a 56 10 f0       	push   $0xf010567a
f0103816:	68 f9 00 00 00       	push   $0xf9
f010381b:	68 7d 5c 10 f0       	push   $0xf0105c7d
f0103820:	e8 84 c8 ff ff       	call   f01000a9 <_panic>
	env_run(curenv);
f0103825:	83 ec 0c             	sub    $0xc,%esp
f0103828:	50                   	push   %eax
f0103829:	e8 1a f7 ff ff       	call   f0102f48 <env_run>

f010382e <Trap_0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(Trap_0, T_DIVIDE)
f010382e:	6a 00                	push   $0x0
f0103830:	6a 00                	push   $0x0
f0103832:	eb 5e                	jmp    f0103892 <_alltraps>

f0103834 <Trap_1>:
TRAPHANDLER_NOEC(Trap_1, T_DEBUG)
f0103834:	6a 00                	push   $0x0
f0103836:	6a 01                	push   $0x1
f0103838:	eb 58                	jmp    f0103892 <_alltraps>

f010383a <Trap_2>:
TRAPHANDLER_NOEC(Trap_2, T_NMI)
f010383a:	6a 00                	push   $0x0
f010383c:	6a 02                	push   $0x2
f010383e:	eb 52                	jmp    f0103892 <_alltraps>

f0103840 <Trap_3>:
TRAPHANDLER_NOEC(Trap_3, T_BRKPT)
f0103840:	6a 00                	push   $0x0
f0103842:	6a 03                	push   $0x3
f0103844:	eb 4c                	jmp    f0103892 <_alltraps>

f0103846 <Trap_4>:
TRAPHANDLER_NOEC(Trap_4, T_OFLOW)
f0103846:	6a 00                	push   $0x0
f0103848:	6a 04                	push   $0x4
f010384a:	eb 46                	jmp    f0103892 <_alltraps>

f010384c <Trap_5>:
TRAPHANDLER_NOEC(Trap_5, T_BOUND)
f010384c:	6a 00                	push   $0x0
f010384e:	6a 05                	push   $0x5
f0103850:	eb 40                	jmp    f0103892 <_alltraps>

f0103852 <Trap_6>:
TRAPHANDLER_NOEC(Trap_6, T_ILLOP)
f0103852:	6a 00                	push   $0x0
f0103854:	6a 06                	push   $0x6
f0103856:	eb 3a                	jmp    f0103892 <_alltraps>

f0103858 <Trap_7>:
TRAPHANDLER_NOEC(Trap_7, T_DEVICE)
f0103858:	6a 00                	push   $0x0
f010385a:	6a 07                	push   $0x7
f010385c:	eb 34                	jmp    f0103892 <_alltraps>

f010385e <Trap_8>:
TRAPHANDLER(Trap_8, T_DBLFLT)
f010385e:	6a 08                	push   $0x8
f0103860:	eb 30                	jmp    f0103892 <_alltraps>

f0103862 <Trap_10>:
TRAPHANDLER(Trap_10, T_TSS)
f0103862:	6a 0a                	push   $0xa
f0103864:	eb 2c                	jmp    f0103892 <_alltraps>

f0103866 <Trap_11>:
TRAPHANDLER(Trap_11, T_SEGNP)
f0103866:	6a 0b                	push   $0xb
f0103868:	eb 28                	jmp    f0103892 <_alltraps>

f010386a <Trap_12>:
TRAPHANDLER(Trap_12, T_STACK)
f010386a:	6a 0c                	push   $0xc
f010386c:	eb 24                	jmp    f0103892 <_alltraps>

f010386e <Trap_13>:
TRAPHANDLER(Trap_13, T_GPFLT)
f010386e:	6a 0d                	push   $0xd
f0103870:	eb 20                	jmp    f0103892 <_alltraps>

f0103872 <Trap_14>:
TRAPHANDLER(Trap_14, T_PGFLT)
f0103872:	6a 0e                	push   $0xe
f0103874:	eb 1c                	jmp    f0103892 <_alltraps>

f0103876 <Trap_16>:
TRAPHANDLER_NOEC(Trap_16, T_FPERR)
f0103876:	6a 00                	push   $0x0
f0103878:	6a 10                	push   $0x10
f010387a:	eb 16                	jmp    f0103892 <_alltraps>

f010387c <Trap_17>:
TRAPHANDLER(Trap_17, T_ALIGN)
f010387c:	6a 11                	push   $0x11
f010387e:	eb 12                	jmp    f0103892 <_alltraps>

f0103880 <Trap_18>:
TRAPHANDLER_NOEC(Trap_18, T_MCHK)
f0103880:	6a 00                	push   $0x0
f0103882:	6a 12                	push   $0x12
f0103884:	eb 0c                	jmp    f0103892 <_alltraps>

f0103886 <Trap_19>:
TRAPHANDLER_NOEC(Trap_19, T_SIMDERR)
f0103886:	6a 00                	push   $0x0
f0103888:	6a 13                	push   $0x13
f010388a:	eb 06                	jmp    f0103892 <_alltraps>

f010388c <Trap_48>:
TRAPHANDLER_NOEC(Trap_48, T_SYSCALL)
f010388c:	6a 00                	push   $0x0
f010388e:	6a 30                	push   $0x30
f0103890:	eb 00                	jmp    f0103892 <_alltraps>

f0103892 <_alltraps>:
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
	pushl %ds
f0103892:	1e                   	push   %ds
    pushl %es
f0103893:	06                   	push   %es
	pushal
f0103894:	60                   	pusha  

	movw $GD_KD, %ax
f0103895:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103899:	8e d8                	mov    %eax,%ds
	movw %ax, %es 
f010389b:	8e c0                	mov    %eax,%es

    pushl %esp
f010389d:	54                   	push   %esp
    call trap	
f010389e:	e8 d2 fe ff ff       	call   f0103775 <trap>

f01038a3 <sys_getenvid>:
}

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
f01038a3:	55                   	push   %ebp
f01038a4:	89 e5                	mov    %esp,%ebp
f01038a6:	83 ec 14             	sub    $0x14,%esp
	cprintf("Entre a f3()\n");
f01038a9:	68 f0 5e 10 f0       	push   $0xf0105ef0
f01038ae:	e8 cf f7 ff ff       	call   f0103082 <cprintf>
	return curenv->env_id;
f01038b3:	a1 c4 5b 19 f0       	mov    0xf0195bc4,%eax
f01038b8:	8b 40 48             	mov    0x48(%eax),%eax
}
f01038bb:	c9                   	leave  
f01038bc:	c3                   	ret    

f01038bd <sys_cputs>:
// Print a string to the system console.
// The string is exactly 'len' characters long.
// Destroys the environment on memory errors.
static void
sys_cputs(const char *s, size_t len)
{
f01038bd:	55                   	push   %ebp
f01038be:	89 e5                	mov    %esp,%ebp
f01038c0:	56                   	push   %esi
f01038c1:	53                   	push   %ebx
f01038c2:	89 c6                	mov    %eax,%esi
f01038c4:	89 d3                	mov    %edx,%ebx
	// Destroy the environment if not.

	// LAB 3: Your code here.
	//MARTIN_TP2_PARTE5
	
	user_mem_assert(curenv,s,len,0);
f01038c6:	6a 00                	push   $0x0
f01038c8:	52                   	push   %edx
f01038c9:	50                   	push   %eax
f01038ca:	ff 35 c4 5b 19 f0    	pushl  0xf0195bc4
f01038d0:	e8 36 ef ff ff       	call   f010280b <user_mem_assert>
	

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01038d5:	83 c4 0c             	add    $0xc,%esp
f01038d8:	56                   	push   %esi
f01038d9:	53                   	push   %ebx
f01038da:	68 fe 5e 10 f0       	push   $0xf0105efe
f01038df:	e8 9e f7 ff ff       	call   f0103082 <cprintf>
}
f01038e4:	83 c4 10             	add    $0x10,%esp
f01038e7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01038ea:	5b                   	pop    %ebx
f01038eb:	5e                   	pop    %esi
f01038ec:	5d                   	pop    %ebp
f01038ed:	c3                   	ret    

f01038ee <sys_cgetc>:

// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
f01038ee:	55                   	push   %ebp
f01038ef:	89 e5                	mov    %esp,%ebp
f01038f1:	83 ec 14             	sub    $0x14,%esp
	cprintf("Entre a f2()\n");
f01038f4:	68 03 5f 10 f0       	push   $0xf0105f03
f01038f9:	e8 84 f7 ff ff       	call   f0103082 <cprintf>
	return cons_getc();
f01038fe:	e8 ab cd ff ff       	call   f01006ae <cons_getc>
}
f0103903:	c9                   	leave  
f0103904:	c3                   	ret    

f0103905 <sys_env_destroy>:
// Returns 0 on success, < 0 on error.  Errors are:
//	-E_BAD_ENV if environment envid doesn't currently exist,
//		or the caller doesn't have permission to change envid.
static int
sys_env_destroy(envid_t envid)
{
f0103905:	55                   	push   %ebp
f0103906:	89 e5                	mov    %esp,%ebp
f0103908:	53                   	push   %ebx
f0103909:	83 ec 20             	sub    $0x20,%esp
f010390c:	89 c3                	mov    %eax,%ebx
	cprintf("Entre a f4()\n");
f010390e:	68 11 5f 10 f0       	push   $0xf0105f11
f0103913:	e8 6a f7 ff ff       	call   f0103082 <cprintf>
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103918:	83 c4 0c             	add    $0xc,%esp
f010391b:	6a 01                	push   $0x1
f010391d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103920:	50                   	push   %eax
f0103921:	53                   	push   %ebx
f0103922:	e8 71 f2 ff ff       	call   f0102b98 <envid2env>
f0103927:	83 c4 10             	add    $0x10,%esp
f010392a:	85 c0                	test   %eax,%eax
f010392c:	78 4b                	js     f0103979 <sys_env_destroy+0x74>
		return r;
	if (e == curenv)
f010392e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103931:	8b 15 c4 5b 19 f0    	mov    0xf0195bc4,%edx
f0103937:	39 d0                	cmp    %edx,%eax
f0103939:	75 15                	jne    f0103950 <sys_env_destroy+0x4b>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f010393b:	83 ec 08             	sub    $0x8,%esp
f010393e:	ff 70 48             	pushl  0x48(%eax)
f0103941:	68 1f 5f 10 f0       	push   $0xf0105f1f
f0103946:	e8 37 f7 ff ff       	call   f0103082 <cprintf>
f010394b:	83 c4 10             	add    $0x10,%esp
f010394e:	eb 16                	jmp    f0103966 <sys_env_destroy+0x61>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103950:	83 ec 04             	sub    $0x4,%esp
f0103953:	ff 70 48             	pushl  0x48(%eax)
f0103956:	ff 72 48             	pushl  0x48(%edx)
f0103959:	68 3a 5f 10 f0       	push   $0xf0105f3a
f010395e:	e8 1f f7 ff ff       	call   f0103082 <cprintf>
f0103963:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f0103966:	83 ec 0c             	sub    $0xc,%esp
f0103969:	ff 75 f4             	pushl  -0xc(%ebp)
f010396c:	e8 87 f5 ff ff       	call   f0102ef8 <env_destroy>
	return 0;
f0103971:	83 c4 10             	add    $0x10,%esp
f0103974:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103979:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010397c:	c9                   	leave  
f010397d:	c3                   	ret    

f010397e <syscall>:

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010397e:	55                   	push   %ebp
f010397f:	89 e5                	mov    %esp,%ebp
f0103981:	53                   	push   %ebx
f0103982:	83 ec 10             	sub    $0x10,%esp
f0103985:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	cprintf("Entre a syscall()\n");
f0103988:	68 52 5f 10 f0       	push   $0xf0105f52
f010398d:	e8 f0 f6 ff ff       	call   f0103082 <cprintf>
	switch (syscallno) {
f0103992:	83 c4 10             	add    $0x10,%esp
f0103995:	83 fb 01             	cmp    $0x1,%ebx
f0103998:	74 1c                	je     f01039b6 <syscall+0x38>
f010399a:	83 fb 01             	cmp    $0x1,%ebx
f010399d:	72 0c                	jb     f01039ab <syscall+0x2d>
f010399f:	83 fb 02             	cmp    $0x2,%ebx
f01039a2:	74 19                	je     f01039bd <syscall+0x3f>
f01039a4:	83 fb 03             	cmp    $0x3,%ebx
f01039a7:	74 1b                	je     f01039c4 <syscall+0x46>
f01039a9:	eb 23                	jmp    f01039ce <syscall+0x50>
	case SYS_cputs:
		sys_cputs((char *)a1, a2);
f01039ab:	8b 55 10             	mov    0x10(%ebp),%edx
f01039ae:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039b1:	e8 07 ff ff ff       	call   f01038bd <sys_cputs>
	case SYS_cgetc:
		return sys_cgetc();
f01039b6:	e8 33 ff ff ff       	call   f01038ee <sys_cgetc>
f01039bb:	eb 16                	jmp    f01039d3 <syscall+0x55>
	case SYS_getenvid:
		return sys_getenvid();
f01039bd:	e8 e1 fe ff ff       	call   f01038a3 <sys_getenvid>
f01039c2:	eb 0f                	jmp    f01039d3 <syscall+0x55>
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f01039c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039c7:	e8 39 ff ff ff       	call   f0103905 <sys_env_destroy>
f01039cc:	eb 05                	jmp    f01039d3 <syscall+0x55>
	default:
		return -E_INVAL;
f01039ce:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f01039d3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01039d6:	c9                   	leave  
f01039d7:	c3                   	ret    

f01039d8 <stab_binsearch>:
stab_binsearch(const struct Stab *stabs,
               int *region_left,
               int *region_right,
               int type,
               uintptr_t addr)
{
f01039d8:	55                   	push   %ebp
f01039d9:	89 e5                	mov    %esp,%ebp
f01039db:	57                   	push   %edi
f01039dc:	56                   	push   %esi
f01039dd:	53                   	push   %ebx
f01039de:	83 ec 14             	sub    $0x14,%esp
f01039e1:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01039e4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01039e7:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01039ea:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01039ed:	8b 1a                	mov    (%edx),%ebx
f01039ef:	8b 01                	mov    (%ecx),%eax
f01039f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01039f4:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01039fb:	eb 7f                	jmp    f0103a7c <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f01039fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103a00:	01 d8                	add    %ebx,%eax
f0103a02:	89 c6                	mov    %eax,%esi
f0103a04:	c1 ee 1f             	shr    $0x1f,%esi
f0103a07:	01 c6                	add    %eax,%esi
f0103a09:	d1 fe                	sar    %esi
f0103a0b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0103a0e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103a11:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103a14:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103a16:	eb 03                	jmp    f0103a1b <stab_binsearch+0x43>
			m--;
f0103a18:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103a1b:	39 c3                	cmp    %eax,%ebx
f0103a1d:	7f 0d                	jg     f0103a2c <stab_binsearch+0x54>
f0103a1f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103a23:	83 ea 0c             	sub    $0xc,%edx
f0103a26:	39 f9                	cmp    %edi,%ecx
f0103a28:	75 ee                	jne    f0103a18 <stab_binsearch+0x40>
f0103a2a:	eb 05                	jmp    f0103a31 <stab_binsearch+0x59>
			m--;
		if (m < l) {  // no match in [l, m]
			l = true_m + 1;
f0103a2c:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0103a2f:	eb 4b                	jmp    f0103a7c <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103a31:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103a34:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103a37:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103a3b:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103a3e:	76 11                	jbe    f0103a51 <stab_binsearch+0x79>
			*region_left = m;
f0103a40:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103a43:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103a45:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103a48:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103a4f:	eb 2b                	jmp    f0103a7c <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103a51:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103a54:	73 14                	jae    f0103a6a <stab_binsearch+0x92>
			*region_right = m - 1;
f0103a56:	83 e8 01             	sub    $0x1,%eax
f0103a59:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103a5c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103a5f:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103a61:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103a68:	eb 12                	jmp    f0103a7c <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103a6a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103a6d:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0103a6f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103a73:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103a75:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
               int type,
               uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103a7c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103a7f:	0f 8e 78 ff ff ff    	jle    f01039fd <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103a85:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103a89:	75 0f                	jne    f0103a9a <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0103a8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a8e:	8b 00                	mov    (%eax),%eax
f0103a90:	83 e8 01             	sub    $0x1,%eax
f0103a93:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103a96:	89 06                	mov    %eax,(%esi)
f0103a98:	eb 2c                	jmp    f0103ac6 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103a9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a9d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103a9f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103aa2:	8b 0e                	mov    (%esi),%ecx
f0103aa4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103aa7:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0103aaa:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103aad:	eb 03                	jmp    f0103ab2 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103aaf:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103ab2:	39 c8                	cmp    %ecx,%eax
f0103ab4:	7e 0b                	jle    f0103ac1 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0103ab6:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103aba:	83 ea 0c             	sub    $0xc,%edx
f0103abd:	39 df                	cmp    %ebx,%edi
f0103abf:	75 ee                	jne    f0103aaf <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103ac1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103ac4:	89 06                	mov    %eax,(%esi)
	}
}
f0103ac6:	83 c4 14             	add    $0x14,%esp
f0103ac9:	5b                   	pop    %ebx
f0103aca:	5e                   	pop    %esi
f0103acb:	5f                   	pop    %edi
f0103acc:	5d                   	pop    %ebp
f0103acd:	c3                   	ret    

f0103ace <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103ace:	55                   	push   %ebp
f0103acf:	89 e5                	mov    %esp,%ebp
f0103ad1:	57                   	push   %edi
f0103ad2:	56                   	push   %esi
f0103ad3:	53                   	push   %ebx
f0103ad4:	83 ec 3c             	sub    $0x3c,%esp
f0103ad7:	8b 75 08             	mov    0x8(%ebp),%esi
f0103ada:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103add:	c7 03 65 5f 10 f0    	movl   $0xf0105f65,(%ebx)
	info->eip_line = 0;
f0103ae3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103aea:	c7 43 08 65 5f 10 f0 	movl   $0xf0105f65,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103af1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103af8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103afb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103b02:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103b08:	77 21                	ja     f0103b2b <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103b0a:	a1 00 00 20 00       	mov    0x200000,%eax
f0103b0f:	89 45 c0             	mov    %eax,-0x40(%ebp)
		stab_end = usd->stab_end;
f0103b12:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0103b17:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f0103b1d:	89 7d b8             	mov    %edi,-0x48(%ebp)
		stabstr_end = usd->stabstr_end;
f0103b20:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0103b26:	89 7d bc             	mov    %edi,-0x44(%ebp)
f0103b29:	eb 1a                	jmp    f0103b45 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103b2b:	c7 45 bc 81 61 10 f0 	movl   $0xf0106181,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103b32:	c7 45 b8 81 61 10 f0 	movl   $0xf0106181,-0x48(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103b39:	b8 80 61 10 f0       	mov    $0xf0106180,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103b3e:	c7 45 c0 80 61 10 f0 	movl   $0xf0106180,-0x40(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103b45:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103b48:	39 7d b8             	cmp    %edi,-0x48(%ebp)
f0103b4b:	0f 83 9a 01 00 00    	jae    f0103ceb <debuginfo_eip+0x21d>
f0103b51:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0103b55:	0f 85 97 01 00 00    	jne    f0103cf2 <debuginfo_eip+0x224>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103b5b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103b62:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103b65:	29 f8                	sub    %edi,%eax
f0103b67:	c1 f8 02             	sar    $0x2,%eax
f0103b6a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103b70:	83 e8 01             	sub    $0x1,%eax
f0103b73:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103b76:	56                   	push   %esi
f0103b77:	6a 64                	push   $0x64
f0103b79:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0103b7c:	89 c1                	mov    %eax,%ecx
f0103b7e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103b81:	89 f8                	mov    %edi,%eax
f0103b83:	e8 50 fe ff ff       	call   f01039d8 <stab_binsearch>
	if (lfile == 0)
f0103b88:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b8b:	83 c4 08             	add    $0x8,%esp
f0103b8e:	85 c0                	test   %eax,%eax
f0103b90:	0f 84 63 01 00 00    	je     f0103cf9 <debuginfo_eip+0x22b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103b96:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103b99:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b9c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103b9f:	56                   	push   %esi
f0103ba0:	6a 24                	push   $0x24
f0103ba2:	8d 45 d8             	lea    -0x28(%ebp),%eax
f0103ba5:	89 c1                	mov    %eax,%ecx
f0103ba7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103baa:	89 f8                	mov    %edi,%eax
f0103bac:	e8 27 fe ff ff       	call   f01039d8 <stab_binsearch>

	if (lfun <= rfun) {
f0103bb1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103bb4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103bb7:	89 55 c4             	mov    %edx,-0x3c(%ebp)
f0103bba:	83 c4 08             	add    $0x8,%esp
f0103bbd:	39 d0                	cmp    %edx,%eax
f0103bbf:	7f 2b                	jg     f0103bec <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103bc1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103bc4:	8d 0c 97             	lea    (%edi,%edx,4),%ecx
f0103bc7:	8b 11                	mov    (%ecx),%edx
f0103bc9:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0103bcc:	2b 7d b8             	sub    -0x48(%ebp),%edi
f0103bcf:	39 fa                	cmp    %edi,%edx
f0103bd1:	73 06                	jae    f0103bd9 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103bd3:	03 55 b8             	add    -0x48(%ebp),%edx
f0103bd6:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103bd9:	8b 51 08             	mov    0x8(%ecx),%edx
f0103bdc:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103bdf:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103be1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103be4:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0103be7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103bea:	eb 0f                	jmp    f0103bfb <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103bec:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103bef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103bf2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103bf5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bf8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103bfb:	83 ec 08             	sub    $0x8,%esp
f0103bfe:	6a 3a                	push   $0x3a
f0103c00:	ff 73 08             	pushl  0x8(%ebx)
f0103c03:	e8 65 08 00 00       	call   f010446d <strfind>
f0103c08:	2b 43 08             	sub    0x8(%ebx),%eax
f0103c0b:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103c0e:	83 c4 08             	add    $0x8,%esp
f0103c11:	56                   	push   %esi
f0103c12:	6a 44                	push   $0x44
f0103c14:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103c17:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103c1a:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103c1d:	89 f0                	mov    %esi,%eax
f0103c1f:	e8 b4 fd ff ff       	call   f01039d8 <stab_binsearch>
	if (lline <= rline) {
f0103c24:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103c27:	83 c4 10             	add    $0x10,%esp
f0103c2a:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0103c2d:	7f 0b                	jg     f0103c3a <debuginfo_eip+0x16c>
		info->eip_line = stabs[lline].n_desc;
f0103c2f:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103c32:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103c37:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile && stabs[lline].n_type != N_SOL &&
f0103c3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103c3d:	89 d0                	mov    %edx,%eax
f0103c3f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103c42:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103c45:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103c48:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0103c4c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0103c4f:	eb 0a                	jmp    f0103c5b <debuginfo_eip+0x18d>
f0103c51:	83 e8 01             	sub    $0x1,%eax
f0103c54:	83 ea 0c             	sub    $0xc,%edx
f0103c57:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0103c5b:	39 c7                	cmp    %eax,%edi
f0103c5d:	7e 05                	jle    f0103c64 <debuginfo_eip+0x196>
f0103c5f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c62:	eb 47                	jmp    f0103cab <debuginfo_eip+0x1dd>
f0103c64:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103c68:	80 f9 84             	cmp    $0x84,%cl
f0103c6b:	75 0e                	jne    f0103c7b <debuginfo_eip+0x1ad>
f0103c6d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c70:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103c74:	74 1c                	je     f0103c92 <debuginfo_eip+0x1c4>
f0103c76:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0103c79:	eb 17                	jmp    f0103c92 <debuginfo_eip+0x1c4>
f0103c7b:	80 f9 64             	cmp    $0x64,%cl
f0103c7e:	75 d1                	jne    f0103c51 <debuginfo_eip+0x183>
	       (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103c80:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103c84:	74 cb                	je     f0103c51 <debuginfo_eip+0x183>
f0103c86:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c89:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0103c8d:	74 03                	je     f0103c92 <debuginfo_eip+0x1c4>
f0103c8f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103c92:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103c95:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0103c98:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0103c9b:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103c9e:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0103ca1:	29 f8                	sub    %edi,%eax
f0103ca3:	39 c2                	cmp    %eax,%edx
f0103ca5:	73 04                	jae    f0103cab <debuginfo_eip+0x1dd>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103ca7:	01 fa                	add    %edi,%edx
f0103ca9:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103cab:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103cae:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103cb1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103cb6:	39 f2                	cmp    %esi,%edx
f0103cb8:	7d 4b                	jge    f0103d05 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
f0103cba:	83 c2 01             	add    $0x1,%edx
f0103cbd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0103cc0:	89 d0                	mov    %edx,%eax
f0103cc2:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103cc5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103cc8:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0103ccb:	eb 04                	jmp    f0103cd1 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103ccd:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103cd1:	39 c6                	cmp    %eax,%esi
f0103cd3:	7e 2b                	jle    f0103d00 <debuginfo_eip+0x232>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103cd5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103cd9:	83 c0 01             	add    $0x1,%eax
f0103cdc:	83 c2 0c             	add    $0xc,%edx
f0103cdf:	80 f9 a0             	cmp    $0xa0,%cl
f0103ce2:	74 e9                	je     f0103ccd <debuginfo_eip+0x1ff>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103ce4:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ce9:	eb 1a                	jmp    f0103d05 <debuginfo_eip+0x237>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103ceb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cf0:	eb 13                	jmp    f0103d05 <debuginfo_eip+0x237>
f0103cf2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cf7:	eb 0c                	jmp    f0103d05 <debuginfo_eip+0x237>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103cf9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103cfe:	eb 05                	jmp    f0103d05 <debuginfo_eip+0x237>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103d00:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d08:	5b                   	pop    %ebx
f0103d09:	5e                   	pop    %esi
f0103d0a:	5f                   	pop    %edi
f0103d0b:	5d                   	pop    %ebp
f0103d0c:	c3                   	ret    

f0103d0d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103d0d:	55                   	push   %ebp
f0103d0e:	89 e5                	mov    %esp,%ebp
f0103d10:	57                   	push   %edi
f0103d11:	56                   	push   %esi
f0103d12:	53                   	push   %ebx
f0103d13:	83 ec 1c             	sub    $0x1c,%esp
f0103d16:	89 c7                	mov    %eax,%edi
f0103d18:	89 d6                	mov    %edx,%esi
f0103d1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103d1d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103d20:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d23:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103d26:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103d29:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103d2e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103d31:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103d34:	39 d3                	cmp    %edx,%ebx
f0103d36:	72 05                	jb     f0103d3d <printnum+0x30>
f0103d38:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103d3b:	77 45                	ja     f0103d82 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103d3d:	83 ec 0c             	sub    $0xc,%esp
f0103d40:	ff 75 18             	pushl  0x18(%ebp)
f0103d43:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d46:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0103d49:	53                   	push   %ebx
f0103d4a:	ff 75 10             	pushl  0x10(%ebp)
f0103d4d:	83 ec 08             	sub    $0x8,%esp
f0103d50:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d53:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d56:	ff 75 dc             	pushl  -0x24(%ebp)
f0103d59:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d5c:	e8 2f 09 00 00       	call   f0104690 <__udivdi3>
f0103d61:	83 c4 18             	add    $0x18,%esp
f0103d64:	52                   	push   %edx
f0103d65:	50                   	push   %eax
f0103d66:	89 f2                	mov    %esi,%edx
f0103d68:	89 f8                	mov    %edi,%eax
f0103d6a:	e8 9e ff ff ff       	call   f0103d0d <printnum>
f0103d6f:	83 c4 20             	add    $0x20,%esp
f0103d72:	eb 18                	jmp    f0103d8c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103d74:	83 ec 08             	sub    $0x8,%esp
f0103d77:	56                   	push   %esi
f0103d78:	ff 75 18             	pushl  0x18(%ebp)
f0103d7b:	ff d7                	call   *%edi
f0103d7d:	83 c4 10             	add    $0x10,%esp
f0103d80:	eb 03                	jmp    f0103d85 <printnum+0x78>
f0103d82:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103d85:	83 eb 01             	sub    $0x1,%ebx
f0103d88:	85 db                	test   %ebx,%ebx
f0103d8a:	7f e8                	jg     f0103d74 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103d8c:	83 ec 08             	sub    $0x8,%esp
f0103d8f:	56                   	push   %esi
f0103d90:	83 ec 04             	sub    $0x4,%esp
f0103d93:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103d96:	ff 75 e0             	pushl  -0x20(%ebp)
f0103d99:	ff 75 dc             	pushl  -0x24(%ebp)
f0103d9c:	ff 75 d8             	pushl  -0x28(%ebp)
f0103d9f:	e8 1c 0a 00 00       	call   f01047c0 <__umoddi3>
f0103da4:	83 c4 14             	add    $0x14,%esp
f0103da7:	0f be 80 6f 5f 10 f0 	movsbl -0xfefa091(%eax),%eax
f0103dae:	50                   	push   %eax
f0103daf:	ff d7                	call   *%edi
}
f0103db1:	83 c4 10             	add    $0x10,%esp
f0103db4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103db7:	5b                   	pop    %ebx
f0103db8:	5e                   	pop    %esi
f0103db9:	5f                   	pop    %edi
f0103dba:	5d                   	pop    %ebp
f0103dbb:	c3                   	ret    

f0103dbc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103dbc:	55                   	push   %ebp
f0103dbd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103dbf:	83 fa 01             	cmp    $0x1,%edx
f0103dc2:	7e 0e                	jle    f0103dd2 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103dc4:	8b 10                	mov    (%eax),%edx
f0103dc6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103dc9:	89 08                	mov    %ecx,(%eax)
f0103dcb:	8b 02                	mov    (%edx),%eax
f0103dcd:	8b 52 04             	mov    0x4(%edx),%edx
f0103dd0:	eb 22                	jmp    f0103df4 <getuint+0x38>
	else if (lflag)
f0103dd2:	85 d2                	test   %edx,%edx
f0103dd4:	74 10                	je     f0103de6 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103dd6:	8b 10                	mov    (%eax),%edx
f0103dd8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103ddb:	89 08                	mov    %ecx,(%eax)
f0103ddd:	8b 02                	mov    (%edx),%eax
f0103ddf:	ba 00 00 00 00       	mov    $0x0,%edx
f0103de4:	eb 0e                	jmp    f0103df4 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103de6:	8b 10                	mov    (%eax),%edx
f0103de8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103deb:	89 08                	mov    %ecx,(%eax)
f0103ded:	8b 02                	mov    (%edx),%eax
f0103def:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103df4:	5d                   	pop    %ebp
f0103df5:	c3                   	ret    

f0103df6 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0103df6:	55                   	push   %ebp
f0103df7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103df9:	83 fa 01             	cmp    $0x1,%edx
f0103dfc:	7e 0e                	jle    f0103e0c <getint+0x16>
		return va_arg(*ap, long long);
f0103dfe:	8b 10                	mov    (%eax),%edx
f0103e00:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103e03:	89 08                	mov    %ecx,(%eax)
f0103e05:	8b 02                	mov    (%edx),%eax
f0103e07:	8b 52 04             	mov    0x4(%edx),%edx
f0103e0a:	eb 1a                	jmp    f0103e26 <getint+0x30>
	else if (lflag)
f0103e0c:	85 d2                	test   %edx,%edx
f0103e0e:	74 0c                	je     f0103e1c <getint+0x26>
		return va_arg(*ap, long);
f0103e10:	8b 10                	mov    (%eax),%edx
f0103e12:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103e15:	89 08                	mov    %ecx,(%eax)
f0103e17:	8b 02                	mov    (%edx),%eax
f0103e19:	99                   	cltd   
f0103e1a:	eb 0a                	jmp    f0103e26 <getint+0x30>
	else
		return va_arg(*ap, int);
f0103e1c:	8b 10                	mov    (%eax),%edx
f0103e1e:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103e21:	89 08                	mov    %ecx,(%eax)
f0103e23:	8b 02                	mov    (%edx),%eax
f0103e25:	99                   	cltd   
}
f0103e26:	5d                   	pop    %ebp
f0103e27:	c3                   	ret    

f0103e28 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103e28:	55                   	push   %ebp
f0103e29:	89 e5                	mov    %esp,%ebp
f0103e2b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103e2e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103e32:	8b 10                	mov    (%eax),%edx
f0103e34:	3b 50 04             	cmp    0x4(%eax),%edx
f0103e37:	73 0a                	jae    f0103e43 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103e39:	8d 4a 01             	lea    0x1(%edx),%ecx
f0103e3c:	89 08                	mov    %ecx,(%eax)
f0103e3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e41:	88 02                	mov    %al,(%edx)
}
f0103e43:	5d                   	pop    %ebp
f0103e44:	c3                   	ret    

f0103e45 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103e45:	55                   	push   %ebp
f0103e46:	89 e5                	mov    %esp,%ebp
f0103e48:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0103e4b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103e4e:	50                   	push   %eax
f0103e4f:	ff 75 10             	pushl  0x10(%ebp)
f0103e52:	ff 75 0c             	pushl  0xc(%ebp)
f0103e55:	ff 75 08             	pushl  0x8(%ebp)
f0103e58:	e8 05 00 00 00       	call   f0103e62 <vprintfmt>
	va_end(ap);
}
f0103e5d:	83 c4 10             	add    $0x10,%esp
f0103e60:	c9                   	leave  
f0103e61:	c3                   	ret    

f0103e62 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103e62:	55                   	push   %ebp
f0103e63:	89 e5                	mov    %esp,%ebp
f0103e65:	57                   	push   %edi
f0103e66:	56                   	push   %esi
f0103e67:	53                   	push   %ebx
f0103e68:	83 ec 2c             	sub    $0x2c,%esp
f0103e6b:	8b 75 08             	mov    0x8(%ebp),%esi
f0103e6e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e71:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103e74:	eb 12                	jmp    f0103e88 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103e76:	85 c0                	test   %eax,%eax
f0103e78:	0f 84 44 03 00 00    	je     f01041c2 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
f0103e7e:	83 ec 08             	sub    $0x8,%esp
f0103e81:	53                   	push   %ebx
f0103e82:	50                   	push   %eax
f0103e83:	ff d6                	call   *%esi
f0103e85:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103e88:	83 c7 01             	add    $0x1,%edi
f0103e8b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0103e8f:	83 f8 25             	cmp    $0x25,%eax
f0103e92:	75 e2                	jne    f0103e76 <vprintfmt+0x14>
f0103e94:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0103e98:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0103e9f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103ea6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0103ead:	ba 00 00 00 00       	mov    $0x0,%edx
f0103eb2:	eb 07                	jmp    f0103ebb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103eb4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103eb7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ebb:	8d 47 01             	lea    0x1(%edi),%eax
f0103ebe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ec1:	0f b6 07             	movzbl (%edi),%eax
f0103ec4:	0f b6 c8             	movzbl %al,%ecx
f0103ec7:	83 e8 23             	sub    $0x23,%eax
f0103eca:	3c 55                	cmp    $0x55,%al
f0103ecc:	0f 87 d5 02 00 00    	ja     f01041a7 <vprintfmt+0x345>
f0103ed2:	0f b6 c0             	movzbl %al,%eax
f0103ed5:	ff 24 85 fc 5f 10 f0 	jmp    *-0xfefa004(,%eax,4)
f0103edc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103edf:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0103ee3:	eb d6                	jmp    f0103ebb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ee5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103ee8:	b8 00 00 00 00       	mov    $0x0,%eax
f0103eed:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ef0:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0103ef3:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0103ef7:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0103efa:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0103efd:	83 fa 09             	cmp    $0x9,%edx
f0103f00:	77 39                	ja     f0103f3b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103f02:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103f05:	eb e9                	jmp    f0103ef0 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103f07:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f0a:	8d 48 04             	lea    0x4(%eax),%ecx
f0103f0d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103f10:	8b 00                	mov    (%eax),%eax
f0103f12:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103f18:	eb 27                	jmp    f0103f41 <vprintfmt+0xdf>
f0103f1a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f1d:	85 c0                	test   %eax,%eax
f0103f1f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103f24:	0f 49 c8             	cmovns %eax,%ecx
f0103f27:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103f2d:	eb 8c                	jmp    f0103ebb <vprintfmt+0x59>
f0103f2f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103f32:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0103f39:	eb 80                	jmp    f0103ebb <vprintfmt+0x59>
f0103f3b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103f3e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0103f41:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103f45:	0f 89 70 ff ff ff    	jns    f0103ebb <vprintfmt+0x59>
				width = precision, precision = -1;
f0103f4b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103f4e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103f51:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0103f58:	e9 5e ff ff ff       	jmp    f0103ebb <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103f5d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103f63:	e9 53 ff ff ff       	jmp    f0103ebb <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103f68:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f6b:	8d 50 04             	lea    0x4(%eax),%edx
f0103f6e:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f71:	83 ec 08             	sub    $0x8,%esp
f0103f74:	53                   	push   %ebx
f0103f75:	ff 30                	pushl  (%eax)
f0103f77:	ff d6                	call   *%esi
			break;
f0103f79:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103f7c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103f7f:	e9 04 ff ff ff       	jmp    f0103e88 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103f84:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f87:	8d 50 04             	lea    0x4(%eax),%edx
f0103f8a:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f8d:	8b 00                	mov    (%eax),%eax
f0103f8f:	99                   	cltd   
f0103f90:	31 d0                	xor    %edx,%eax
f0103f92:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103f94:	83 f8 06             	cmp    $0x6,%eax
f0103f97:	7f 0b                	jg     f0103fa4 <vprintfmt+0x142>
f0103f99:	8b 14 85 54 61 10 f0 	mov    -0xfef9eac(,%eax,4),%edx
f0103fa0:	85 d2                	test   %edx,%edx
f0103fa2:	75 18                	jne    f0103fbc <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0103fa4:	50                   	push   %eax
f0103fa5:	68 87 5f 10 f0       	push   $0xf0105f87
f0103faa:	53                   	push   %ebx
f0103fab:	56                   	push   %esi
f0103fac:	e8 94 fe ff ff       	call   f0103e45 <printfmt>
f0103fb1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fb4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103fb7:	e9 cc fe ff ff       	jmp    f0103e88 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0103fbc:	52                   	push   %edx
f0103fbd:	68 8c 56 10 f0       	push   $0xf010568c
f0103fc2:	53                   	push   %ebx
f0103fc3:	56                   	push   %esi
f0103fc4:	e8 7c fe ff ff       	call   f0103e45 <printfmt>
f0103fc9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fcc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103fcf:	e9 b4 fe ff ff       	jmp    f0103e88 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103fd4:	8b 45 14             	mov    0x14(%ebp),%eax
f0103fd7:	8d 50 04             	lea    0x4(%eax),%edx
f0103fda:	89 55 14             	mov    %edx,0x14(%ebp)
f0103fdd:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0103fdf:	85 ff                	test   %edi,%edi
f0103fe1:	b8 80 5f 10 f0       	mov    $0xf0105f80,%eax
f0103fe6:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0103fe9:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103fed:	0f 8e 94 00 00 00    	jle    f0104087 <vprintfmt+0x225>
f0103ff3:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0103ff7:	0f 84 98 00 00 00    	je     f0104095 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0103ffd:	83 ec 08             	sub    $0x8,%esp
f0104000:	ff 75 d0             	pushl  -0x30(%ebp)
f0104003:	57                   	push   %edi
f0104004:	e8 1a 03 00 00       	call   f0104323 <strnlen>
f0104009:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010400c:	29 c1                	sub    %eax,%ecx
f010400e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104011:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104014:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104018:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010401b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010401e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104020:	eb 0f                	jmp    f0104031 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0104022:	83 ec 08             	sub    $0x8,%esp
f0104025:	53                   	push   %ebx
f0104026:	ff 75 e0             	pushl  -0x20(%ebp)
f0104029:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010402b:	83 ef 01             	sub    $0x1,%edi
f010402e:	83 c4 10             	add    $0x10,%esp
f0104031:	85 ff                	test   %edi,%edi
f0104033:	7f ed                	jg     f0104022 <vprintfmt+0x1c0>
f0104035:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104038:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010403b:	85 c9                	test   %ecx,%ecx
f010403d:	b8 00 00 00 00       	mov    $0x0,%eax
f0104042:	0f 49 c1             	cmovns %ecx,%eax
f0104045:	29 c1                	sub    %eax,%ecx
f0104047:	89 75 08             	mov    %esi,0x8(%ebp)
f010404a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010404d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104050:	89 cb                	mov    %ecx,%ebx
f0104052:	eb 4d                	jmp    f01040a1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104054:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104058:	74 1b                	je     f0104075 <vprintfmt+0x213>
f010405a:	0f be c0             	movsbl %al,%eax
f010405d:	83 e8 20             	sub    $0x20,%eax
f0104060:	83 f8 5e             	cmp    $0x5e,%eax
f0104063:	76 10                	jbe    f0104075 <vprintfmt+0x213>
					putch('?', putdat);
f0104065:	83 ec 08             	sub    $0x8,%esp
f0104068:	ff 75 0c             	pushl  0xc(%ebp)
f010406b:	6a 3f                	push   $0x3f
f010406d:	ff 55 08             	call   *0x8(%ebp)
f0104070:	83 c4 10             	add    $0x10,%esp
f0104073:	eb 0d                	jmp    f0104082 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0104075:	83 ec 08             	sub    $0x8,%esp
f0104078:	ff 75 0c             	pushl  0xc(%ebp)
f010407b:	52                   	push   %edx
f010407c:	ff 55 08             	call   *0x8(%ebp)
f010407f:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104082:	83 eb 01             	sub    $0x1,%ebx
f0104085:	eb 1a                	jmp    f01040a1 <vprintfmt+0x23f>
f0104087:	89 75 08             	mov    %esi,0x8(%ebp)
f010408a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010408d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104090:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104093:	eb 0c                	jmp    f01040a1 <vprintfmt+0x23f>
f0104095:	89 75 08             	mov    %esi,0x8(%ebp)
f0104098:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010409b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010409e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01040a1:	83 c7 01             	add    $0x1,%edi
f01040a4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01040a8:	0f be d0             	movsbl %al,%edx
f01040ab:	85 d2                	test   %edx,%edx
f01040ad:	74 23                	je     f01040d2 <vprintfmt+0x270>
f01040af:	85 f6                	test   %esi,%esi
f01040b1:	78 a1                	js     f0104054 <vprintfmt+0x1f2>
f01040b3:	83 ee 01             	sub    $0x1,%esi
f01040b6:	79 9c                	jns    f0104054 <vprintfmt+0x1f2>
f01040b8:	89 df                	mov    %ebx,%edi
f01040ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01040bd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01040c0:	eb 18                	jmp    f01040da <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01040c2:	83 ec 08             	sub    $0x8,%esp
f01040c5:	53                   	push   %ebx
f01040c6:	6a 20                	push   $0x20
f01040c8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01040ca:	83 ef 01             	sub    $0x1,%edi
f01040cd:	83 c4 10             	add    $0x10,%esp
f01040d0:	eb 08                	jmp    f01040da <vprintfmt+0x278>
f01040d2:	89 df                	mov    %ebx,%edi
f01040d4:	8b 75 08             	mov    0x8(%ebp),%esi
f01040d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01040da:	85 ff                	test   %edi,%edi
f01040dc:	7f e4                	jg     f01040c2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040de:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040e1:	e9 a2 fd ff ff       	jmp    f0103e88 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01040e6:	8d 45 14             	lea    0x14(%ebp),%eax
f01040e9:	e8 08 fd ff ff       	call   f0103df6 <getint>
f01040ee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01040f1:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01040f4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01040f9:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01040fd:	79 74                	jns    f0104173 <vprintfmt+0x311>
				putch('-', putdat);
f01040ff:	83 ec 08             	sub    $0x8,%esp
f0104102:	53                   	push   %ebx
f0104103:	6a 2d                	push   $0x2d
f0104105:	ff d6                	call   *%esi
				num = -(long long) num;
f0104107:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010410a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010410d:	f7 d8                	neg    %eax
f010410f:	83 d2 00             	adc    $0x0,%edx
f0104112:	f7 da                	neg    %edx
f0104114:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104117:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010411c:	eb 55                	jmp    f0104173 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010411e:	8d 45 14             	lea    0x14(%ebp),%eax
f0104121:	e8 96 fc ff ff       	call   f0103dbc <getuint>
			base = 10;
f0104126:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010412b:	eb 46                	jmp    f0104173 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f010412d:	8d 45 14             	lea    0x14(%ebp),%eax
f0104130:	e8 87 fc ff ff       	call   f0103dbc <getuint>
			base = 8;
f0104135:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f010413a:	eb 37                	jmp    f0104173 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
f010413c:	83 ec 08             	sub    $0x8,%esp
f010413f:	53                   	push   %ebx
f0104140:	6a 30                	push   $0x30
f0104142:	ff d6                	call   *%esi
			putch('x', putdat);
f0104144:	83 c4 08             	add    $0x8,%esp
f0104147:	53                   	push   %ebx
f0104148:	6a 78                	push   $0x78
f010414a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010414c:	8b 45 14             	mov    0x14(%ebp),%eax
f010414f:	8d 50 04             	lea    0x4(%eax),%edx
f0104152:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104155:	8b 00                	mov    (%eax),%eax
f0104157:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010415c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010415f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104164:	eb 0d                	jmp    f0104173 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104166:	8d 45 14             	lea    0x14(%ebp),%eax
f0104169:	e8 4e fc ff ff       	call   f0103dbc <getuint>
			base = 16;
f010416e:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104173:	83 ec 0c             	sub    $0xc,%esp
f0104176:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010417a:	57                   	push   %edi
f010417b:	ff 75 e0             	pushl  -0x20(%ebp)
f010417e:	51                   	push   %ecx
f010417f:	52                   	push   %edx
f0104180:	50                   	push   %eax
f0104181:	89 da                	mov    %ebx,%edx
f0104183:	89 f0                	mov    %esi,%eax
f0104185:	e8 83 fb ff ff       	call   f0103d0d <printnum>
			break;
f010418a:	83 c4 20             	add    $0x20,%esp
f010418d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104190:	e9 f3 fc ff ff       	jmp    f0103e88 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104195:	83 ec 08             	sub    $0x8,%esp
f0104198:	53                   	push   %ebx
f0104199:	51                   	push   %ecx
f010419a:	ff d6                	call   *%esi
			break;
f010419c:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010419f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01041a2:	e9 e1 fc ff ff       	jmp    f0103e88 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01041a7:	83 ec 08             	sub    $0x8,%esp
f01041aa:	53                   	push   %ebx
f01041ab:	6a 25                	push   $0x25
f01041ad:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01041af:	83 c4 10             	add    $0x10,%esp
f01041b2:	eb 03                	jmp    f01041b7 <vprintfmt+0x355>
f01041b4:	83 ef 01             	sub    $0x1,%edi
f01041b7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01041bb:	75 f7                	jne    f01041b4 <vprintfmt+0x352>
f01041bd:	e9 c6 fc ff ff       	jmp    f0103e88 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01041c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01041c5:	5b                   	pop    %ebx
f01041c6:	5e                   	pop    %esi
f01041c7:	5f                   	pop    %edi
f01041c8:	5d                   	pop    %ebp
f01041c9:	c3                   	ret    

f01041ca <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01041ca:	55                   	push   %ebp
f01041cb:	89 e5                	mov    %esp,%ebp
f01041cd:	83 ec 18             	sub    $0x18,%esp
f01041d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01041d3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01041d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01041d9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01041dd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01041e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01041e7:	85 c0                	test   %eax,%eax
f01041e9:	74 26                	je     f0104211 <vsnprintf+0x47>
f01041eb:	85 d2                	test   %edx,%edx
f01041ed:	7e 22                	jle    f0104211 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01041ef:	ff 75 14             	pushl  0x14(%ebp)
f01041f2:	ff 75 10             	pushl  0x10(%ebp)
f01041f5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01041f8:	50                   	push   %eax
f01041f9:	68 28 3e 10 f0       	push   $0xf0103e28
f01041fe:	e8 5f fc ff ff       	call   f0103e62 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104203:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104206:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104209:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010420c:	83 c4 10             	add    $0x10,%esp
f010420f:	eb 05                	jmp    f0104216 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104211:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104216:	c9                   	leave  
f0104217:	c3                   	ret    

f0104218 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104218:	55                   	push   %ebp
f0104219:	89 e5                	mov    %esp,%ebp
f010421b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010421e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104221:	50                   	push   %eax
f0104222:	ff 75 10             	pushl  0x10(%ebp)
f0104225:	ff 75 0c             	pushl  0xc(%ebp)
f0104228:	ff 75 08             	pushl  0x8(%ebp)
f010422b:	e8 9a ff ff ff       	call   f01041ca <vsnprintf>
	va_end(ap);

	return rc;
}
f0104230:	c9                   	leave  
f0104231:	c3                   	ret    

f0104232 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104232:	55                   	push   %ebp
f0104233:	89 e5                	mov    %esp,%ebp
f0104235:	57                   	push   %edi
f0104236:	56                   	push   %esi
f0104237:	53                   	push   %ebx
f0104238:	83 ec 0c             	sub    $0xc,%esp
f010423b:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010423e:	85 c0                	test   %eax,%eax
f0104240:	74 11                	je     f0104253 <readline+0x21>
		cprintf("%s", prompt);
f0104242:	83 ec 08             	sub    $0x8,%esp
f0104245:	50                   	push   %eax
f0104246:	68 8c 56 10 f0       	push   $0xf010568c
f010424b:	e8 32 ee ff ff       	call   f0103082 <cprintf>
f0104250:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104253:	83 ec 0c             	sub    $0xc,%esp
f0104256:	6a 00                	push   $0x0
f0104258:	e8 e7 c4 ff ff       	call   f0100744 <iscons>
f010425d:	89 c7                	mov    %eax,%edi
f010425f:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104262:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104267:	e8 c7 c4 ff ff       	call   f0100733 <getchar>
f010426c:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010426e:	85 c0                	test   %eax,%eax
f0104270:	79 18                	jns    f010428a <readline+0x58>
			cprintf("read error: %e\n", c);
f0104272:	83 ec 08             	sub    $0x8,%esp
f0104275:	50                   	push   %eax
f0104276:	68 70 61 10 f0       	push   $0xf0106170
f010427b:	e8 02 ee ff ff       	call   f0103082 <cprintf>
			return NULL;
f0104280:	83 c4 10             	add    $0x10,%esp
f0104283:	b8 00 00 00 00       	mov    $0x0,%eax
f0104288:	eb 79                	jmp    f0104303 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010428a:	83 f8 08             	cmp    $0x8,%eax
f010428d:	0f 94 c2             	sete   %dl
f0104290:	83 f8 7f             	cmp    $0x7f,%eax
f0104293:	0f 94 c0             	sete   %al
f0104296:	08 c2                	or     %al,%dl
f0104298:	74 1a                	je     f01042b4 <readline+0x82>
f010429a:	85 f6                	test   %esi,%esi
f010429c:	7e 16                	jle    f01042b4 <readline+0x82>
			if (echoing)
f010429e:	85 ff                	test   %edi,%edi
f01042a0:	74 0d                	je     f01042af <readline+0x7d>
				cputchar('\b');
f01042a2:	83 ec 0c             	sub    $0xc,%esp
f01042a5:	6a 08                	push   $0x8
f01042a7:	e8 77 c4 ff ff       	call   f0100723 <cputchar>
f01042ac:	83 c4 10             	add    $0x10,%esp
			i--;
f01042af:	83 ee 01             	sub    $0x1,%esi
f01042b2:	eb b3                	jmp    f0104267 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01042b4:	83 fb 1f             	cmp    $0x1f,%ebx
f01042b7:	7e 23                	jle    f01042dc <readline+0xaa>
f01042b9:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01042bf:	7f 1b                	jg     f01042dc <readline+0xaa>
			if (echoing)
f01042c1:	85 ff                	test   %edi,%edi
f01042c3:	74 0c                	je     f01042d1 <readline+0x9f>
				cputchar(c);
f01042c5:	83 ec 0c             	sub    $0xc,%esp
f01042c8:	53                   	push   %ebx
f01042c9:	e8 55 c4 ff ff       	call   f0100723 <cputchar>
f01042ce:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01042d1:	88 9e 80 64 19 f0    	mov    %bl,-0xfe69b80(%esi)
f01042d7:	8d 76 01             	lea    0x1(%esi),%esi
f01042da:	eb 8b                	jmp    f0104267 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01042dc:	83 fb 0a             	cmp    $0xa,%ebx
f01042df:	74 05                	je     f01042e6 <readline+0xb4>
f01042e1:	83 fb 0d             	cmp    $0xd,%ebx
f01042e4:	75 81                	jne    f0104267 <readline+0x35>
			if (echoing)
f01042e6:	85 ff                	test   %edi,%edi
f01042e8:	74 0d                	je     f01042f7 <readline+0xc5>
				cputchar('\n');
f01042ea:	83 ec 0c             	sub    $0xc,%esp
f01042ed:	6a 0a                	push   $0xa
f01042ef:	e8 2f c4 ff ff       	call   f0100723 <cputchar>
f01042f4:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01042f7:	c6 86 80 64 19 f0 00 	movb   $0x0,-0xfe69b80(%esi)
			return buf;
f01042fe:	b8 80 64 19 f0       	mov    $0xf0196480,%eax
		}
	}
}
f0104303:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104306:	5b                   	pop    %ebx
f0104307:	5e                   	pop    %esi
f0104308:	5f                   	pop    %edi
f0104309:	5d                   	pop    %ebp
f010430a:	c3                   	ret    

f010430b <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010430b:	55                   	push   %ebp
f010430c:	89 e5                	mov    %esp,%ebp
f010430e:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104311:	b8 00 00 00 00       	mov    $0x0,%eax
f0104316:	eb 03                	jmp    f010431b <strlen+0x10>
		n++;
f0104318:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010431b:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010431f:	75 f7                	jne    f0104318 <strlen+0xd>
		n++;
	return n;
}
f0104321:	5d                   	pop    %ebp
f0104322:	c3                   	ret    

f0104323 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104323:	55                   	push   %ebp
f0104324:	89 e5                	mov    %esp,%ebp
f0104326:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104329:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010432c:	ba 00 00 00 00       	mov    $0x0,%edx
f0104331:	eb 03                	jmp    f0104336 <strnlen+0x13>
		n++;
f0104333:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104336:	39 c2                	cmp    %eax,%edx
f0104338:	74 08                	je     f0104342 <strnlen+0x1f>
f010433a:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f010433e:	75 f3                	jne    f0104333 <strnlen+0x10>
f0104340:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104342:	5d                   	pop    %ebp
f0104343:	c3                   	ret    

f0104344 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104344:	55                   	push   %ebp
f0104345:	89 e5                	mov    %esp,%ebp
f0104347:	53                   	push   %ebx
f0104348:	8b 45 08             	mov    0x8(%ebp),%eax
f010434b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010434e:	89 c2                	mov    %eax,%edx
f0104350:	83 c2 01             	add    $0x1,%edx
f0104353:	83 c1 01             	add    $0x1,%ecx
f0104356:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010435a:	88 5a ff             	mov    %bl,-0x1(%edx)
f010435d:	84 db                	test   %bl,%bl
f010435f:	75 ef                	jne    f0104350 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104361:	5b                   	pop    %ebx
f0104362:	5d                   	pop    %ebp
f0104363:	c3                   	ret    

f0104364 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104364:	55                   	push   %ebp
f0104365:	89 e5                	mov    %esp,%ebp
f0104367:	53                   	push   %ebx
f0104368:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010436b:	53                   	push   %ebx
f010436c:	e8 9a ff ff ff       	call   f010430b <strlen>
f0104371:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104374:	ff 75 0c             	pushl  0xc(%ebp)
f0104377:	01 d8                	add    %ebx,%eax
f0104379:	50                   	push   %eax
f010437a:	e8 c5 ff ff ff       	call   f0104344 <strcpy>
	return dst;
}
f010437f:	89 d8                	mov    %ebx,%eax
f0104381:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104384:	c9                   	leave  
f0104385:	c3                   	ret    

f0104386 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104386:	55                   	push   %ebp
f0104387:	89 e5                	mov    %esp,%ebp
f0104389:	56                   	push   %esi
f010438a:	53                   	push   %ebx
f010438b:	8b 75 08             	mov    0x8(%ebp),%esi
f010438e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104391:	89 f3                	mov    %esi,%ebx
f0104393:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104396:	89 f2                	mov    %esi,%edx
f0104398:	eb 0f                	jmp    f01043a9 <strncpy+0x23>
		*dst++ = *src;
f010439a:	83 c2 01             	add    $0x1,%edx
f010439d:	0f b6 01             	movzbl (%ecx),%eax
f01043a0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01043a3:	80 39 01             	cmpb   $0x1,(%ecx)
f01043a6:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01043a9:	39 da                	cmp    %ebx,%edx
f01043ab:	75 ed                	jne    f010439a <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01043ad:	89 f0                	mov    %esi,%eax
f01043af:	5b                   	pop    %ebx
f01043b0:	5e                   	pop    %esi
f01043b1:	5d                   	pop    %ebp
f01043b2:	c3                   	ret    

f01043b3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01043b3:	55                   	push   %ebp
f01043b4:	89 e5                	mov    %esp,%ebp
f01043b6:	56                   	push   %esi
f01043b7:	53                   	push   %ebx
f01043b8:	8b 75 08             	mov    0x8(%ebp),%esi
f01043bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01043be:	8b 55 10             	mov    0x10(%ebp),%edx
f01043c1:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01043c3:	85 d2                	test   %edx,%edx
f01043c5:	74 21                	je     f01043e8 <strlcpy+0x35>
f01043c7:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01043cb:	89 f2                	mov    %esi,%edx
f01043cd:	eb 09                	jmp    f01043d8 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01043cf:	83 c2 01             	add    $0x1,%edx
f01043d2:	83 c1 01             	add    $0x1,%ecx
f01043d5:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01043d8:	39 c2                	cmp    %eax,%edx
f01043da:	74 09                	je     f01043e5 <strlcpy+0x32>
f01043dc:	0f b6 19             	movzbl (%ecx),%ebx
f01043df:	84 db                	test   %bl,%bl
f01043e1:	75 ec                	jne    f01043cf <strlcpy+0x1c>
f01043e3:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01043e5:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01043e8:	29 f0                	sub    %esi,%eax
}
f01043ea:	5b                   	pop    %ebx
f01043eb:	5e                   	pop    %esi
f01043ec:	5d                   	pop    %ebp
f01043ed:	c3                   	ret    

f01043ee <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01043ee:	55                   	push   %ebp
f01043ef:	89 e5                	mov    %esp,%ebp
f01043f1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01043f4:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01043f7:	eb 06                	jmp    f01043ff <strcmp+0x11>
		p++, q++;
f01043f9:	83 c1 01             	add    $0x1,%ecx
f01043fc:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01043ff:	0f b6 01             	movzbl (%ecx),%eax
f0104402:	84 c0                	test   %al,%al
f0104404:	74 04                	je     f010440a <strcmp+0x1c>
f0104406:	3a 02                	cmp    (%edx),%al
f0104408:	74 ef                	je     f01043f9 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010440a:	0f b6 c0             	movzbl %al,%eax
f010440d:	0f b6 12             	movzbl (%edx),%edx
f0104410:	29 d0                	sub    %edx,%eax
}
f0104412:	5d                   	pop    %ebp
f0104413:	c3                   	ret    

f0104414 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104414:	55                   	push   %ebp
f0104415:	89 e5                	mov    %esp,%ebp
f0104417:	53                   	push   %ebx
f0104418:	8b 45 08             	mov    0x8(%ebp),%eax
f010441b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010441e:	89 c3                	mov    %eax,%ebx
f0104420:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104423:	eb 06                	jmp    f010442b <strncmp+0x17>
		n--, p++, q++;
f0104425:	83 c0 01             	add    $0x1,%eax
f0104428:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010442b:	39 d8                	cmp    %ebx,%eax
f010442d:	74 15                	je     f0104444 <strncmp+0x30>
f010442f:	0f b6 08             	movzbl (%eax),%ecx
f0104432:	84 c9                	test   %cl,%cl
f0104434:	74 04                	je     f010443a <strncmp+0x26>
f0104436:	3a 0a                	cmp    (%edx),%cl
f0104438:	74 eb                	je     f0104425 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010443a:	0f b6 00             	movzbl (%eax),%eax
f010443d:	0f b6 12             	movzbl (%edx),%edx
f0104440:	29 d0                	sub    %edx,%eax
f0104442:	eb 05                	jmp    f0104449 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104444:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104449:	5b                   	pop    %ebx
f010444a:	5d                   	pop    %ebp
f010444b:	c3                   	ret    

f010444c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010444c:	55                   	push   %ebp
f010444d:	89 e5                	mov    %esp,%ebp
f010444f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104452:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104456:	eb 07                	jmp    f010445f <strchr+0x13>
		if (*s == c)
f0104458:	38 ca                	cmp    %cl,%dl
f010445a:	74 0f                	je     f010446b <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010445c:	83 c0 01             	add    $0x1,%eax
f010445f:	0f b6 10             	movzbl (%eax),%edx
f0104462:	84 d2                	test   %dl,%dl
f0104464:	75 f2                	jne    f0104458 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104466:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010446b:	5d                   	pop    %ebp
f010446c:	c3                   	ret    

f010446d <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010446d:	55                   	push   %ebp
f010446e:	89 e5                	mov    %esp,%ebp
f0104470:	8b 45 08             	mov    0x8(%ebp),%eax
f0104473:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104477:	eb 03                	jmp    f010447c <strfind+0xf>
f0104479:	83 c0 01             	add    $0x1,%eax
f010447c:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010447f:	38 ca                	cmp    %cl,%dl
f0104481:	74 04                	je     f0104487 <strfind+0x1a>
f0104483:	84 d2                	test   %dl,%dl
f0104485:	75 f2                	jne    f0104479 <strfind+0xc>
			break;
	return (char *) s;
}
f0104487:	5d                   	pop    %ebp
f0104488:	c3                   	ret    

f0104489 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104489:	55                   	push   %ebp
f010448a:	89 e5                	mov    %esp,%ebp
f010448c:	57                   	push   %edi
f010448d:	56                   	push   %esi
f010448e:	53                   	push   %ebx
f010448f:	8b 55 08             	mov    0x8(%ebp),%edx
f0104492:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
f0104495:	85 c9                	test   %ecx,%ecx
f0104497:	74 37                	je     f01044d0 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104499:	f6 c2 03             	test   $0x3,%dl
f010449c:	75 2a                	jne    f01044c8 <memset+0x3f>
f010449e:	f6 c1 03             	test   $0x3,%cl
f01044a1:	75 25                	jne    f01044c8 <memset+0x3f>
		c &= 0xFF;
f01044a3:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01044a7:	89 df                	mov    %ebx,%edi
f01044a9:	c1 e7 08             	shl    $0x8,%edi
f01044ac:	89 de                	mov    %ebx,%esi
f01044ae:	c1 e6 18             	shl    $0x18,%esi
f01044b1:	89 d8                	mov    %ebx,%eax
f01044b3:	c1 e0 10             	shl    $0x10,%eax
f01044b6:	09 f0                	or     %esi,%eax
f01044b8:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
f01044ba:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01044bd:	89 f8                	mov    %edi,%eax
f01044bf:	09 d8                	or     %ebx,%eax
f01044c1:	89 d7                	mov    %edx,%edi
f01044c3:	fc                   	cld    
f01044c4:	f3 ab                	rep stos %eax,%es:(%edi)
f01044c6:	eb 08                	jmp    f01044d0 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01044c8:	89 d7                	mov    %edx,%edi
f01044ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01044cd:	fc                   	cld    
f01044ce:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
f01044d0:	89 d0                	mov    %edx,%eax
f01044d2:	5b                   	pop    %ebx
f01044d3:	5e                   	pop    %esi
f01044d4:	5f                   	pop    %edi
f01044d5:	5d                   	pop    %ebp
f01044d6:	c3                   	ret    

f01044d7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01044d7:	55                   	push   %ebp
f01044d8:	89 e5                	mov    %esp,%ebp
f01044da:	57                   	push   %edi
f01044db:	56                   	push   %esi
f01044dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01044df:	8b 75 0c             	mov    0xc(%ebp),%esi
f01044e2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01044e5:	39 c6                	cmp    %eax,%esi
f01044e7:	73 35                	jae    f010451e <memmove+0x47>
f01044e9:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01044ec:	39 d0                	cmp    %edx,%eax
f01044ee:	73 2e                	jae    f010451e <memmove+0x47>
		s += n;
		d += n;
f01044f0:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01044f3:	89 d6                	mov    %edx,%esi
f01044f5:	09 fe                	or     %edi,%esi
f01044f7:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01044fd:	75 13                	jne    f0104512 <memmove+0x3b>
f01044ff:	f6 c1 03             	test   $0x3,%cl
f0104502:	75 0e                	jne    f0104512 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0104504:	83 ef 04             	sub    $0x4,%edi
f0104507:	8d 72 fc             	lea    -0x4(%edx),%esi
f010450a:	c1 e9 02             	shr    $0x2,%ecx
f010450d:	fd                   	std    
f010450e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104510:	eb 09                	jmp    f010451b <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104512:	83 ef 01             	sub    $0x1,%edi
f0104515:	8d 72 ff             	lea    -0x1(%edx),%esi
f0104518:	fd                   	std    
f0104519:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010451b:	fc                   	cld    
f010451c:	eb 1d                	jmp    f010453b <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010451e:	89 f2                	mov    %esi,%edx
f0104520:	09 c2                	or     %eax,%edx
f0104522:	f6 c2 03             	test   $0x3,%dl
f0104525:	75 0f                	jne    f0104536 <memmove+0x5f>
f0104527:	f6 c1 03             	test   $0x3,%cl
f010452a:	75 0a                	jne    f0104536 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010452c:	c1 e9 02             	shr    $0x2,%ecx
f010452f:	89 c7                	mov    %eax,%edi
f0104531:	fc                   	cld    
f0104532:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104534:	eb 05                	jmp    f010453b <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104536:	89 c7                	mov    %eax,%edi
f0104538:	fc                   	cld    
f0104539:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010453b:	5e                   	pop    %esi
f010453c:	5f                   	pop    %edi
f010453d:	5d                   	pop    %ebp
f010453e:	c3                   	ret    

f010453f <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010453f:	55                   	push   %ebp
f0104540:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104542:	ff 75 10             	pushl  0x10(%ebp)
f0104545:	ff 75 0c             	pushl  0xc(%ebp)
f0104548:	ff 75 08             	pushl  0x8(%ebp)
f010454b:	e8 87 ff ff ff       	call   f01044d7 <memmove>
}
f0104550:	c9                   	leave  
f0104551:	c3                   	ret    

f0104552 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104552:	55                   	push   %ebp
f0104553:	89 e5                	mov    %esp,%ebp
f0104555:	56                   	push   %esi
f0104556:	53                   	push   %ebx
f0104557:	8b 45 08             	mov    0x8(%ebp),%eax
f010455a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010455d:	89 c6                	mov    %eax,%esi
f010455f:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104562:	eb 1a                	jmp    f010457e <memcmp+0x2c>
		if (*s1 != *s2)
f0104564:	0f b6 08             	movzbl (%eax),%ecx
f0104567:	0f b6 1a             	movzbl (%edx),%ebx
f010456a:	38 d9                	cmp    %bl,%cl
f010456c:	74 0a                	je     f0104578 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f010456e:	0f b6 c1             	movzbl %cl,%eax
f0104571:	0f b6 db             	movzbl %bl,%ebx
f0104574:	29 d8                	sub    %ebx,%eax
f0104576:	eb 0f                	jmp    f0104587 <memcmp+0x35>
		s1++, s2++;
f0104578:	83 c0 01             	add    $0x1,%eax
f010457b:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010457e:	39 f0                	cmp    %esi,%eax
f0104580:	75 e2                	jne    f0104564 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104582:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104587:	5b                   	pop    %ebx
f0104588:	5e                   	pop    %esi
f0104589:	5d                   	pop    %ebp
f010458a:	c3                   	ret    

f010458b <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010458b:	55                   	push   %ebp
f010458c:	89 e5                	mov    %esp,%ebp
f010458e:	53                   	push   %ebx
f010458f:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104592:	89 c1                	mov    %eax,%ecx
f0104594:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0104597:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010459b:	eb 0a                	jmp    f01045a7 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010459d:	0f b6 10             	movzbl (%eax),%edx
f01045a0:	39 da                	cmp    %ebx,%edx
f01045a2:	74 07                	je     f01045ab <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01045a4:	83 c0 01             	add    $0x1,%eax
f01045a7:	39 c8                	cmp    %ecx,%eax
f01045a9:	72 f2                	jb     f010459d <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01045ab:	5b                   	pop    %ebx
f01045ac:	5d                   	pop    %ebp
f01045ad:	c3                   	ret    

f01045ae <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01045ae:	55                   	push   %ebp
f01045af:	89 e5                	mov    %esp,%ebp
f01045b1:	57                   	push   %edi
f01045b2:	56                   	push   %esi
f01045b3:	53                   	push   %ebx
f01045b4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01045b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01045ba:	eb 03                	jmp    f01045bf <strtol+0x11>
		s++;
f01045bc:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01045bf:	0f b6 01             	movzbl (%ecx),%eax
f01045c2:	3c 20                	cmp    $0x20,%al
f01045c4:	74 f6                	je     f01045bc <strtol+0xe>
f01045c6:	3c 09                	cmp    $0x9,%al
f01045c8:	74 f2                	je     f01045bc <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01045ca:	3c 2b                	cmp    $0x2b,%al
f01045cc:	75 0a                	jne    f01045d8 <strtol+0x2a>
		s++;
f01045ce:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01045d1:	bf 00 00 00 00       	mov    $0x0,%edi
f01045d6:	eb 11                	jmp    f01045e9 <strtol+0x3b>
f01045d8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01045dd:	3c 2d                	cmp    $0x2d,%al
f01045df:	75 08                	jne    f01045e9 <strtol+0x3b>
		s++, neg = 1;
f01045e1:	83 c1 01             	add    $0x1,%ecx
f01045e4:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01045e9:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01045ef:	75 15                	jne    f0104606 <strtol+0x58>
f01045f1:	80 39 30             	cmpb   $0x30,(%ecx)
f01045f4:	75 10                	jne    f0104606 <strtol+0x58>
f01045f6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01045fa:	75 7c                	jne    f0104678 <strtol+0xca>
		s += 2, base = 16;
f01045fc:	83 c1 02             	add    $0x2,%ecx
f01045ff:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104604:	eb 16                	jmp    f010461c <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0104606:	85 db                	test   %ebx,%ebx
f0104608:	75 12                	jne    f010461c <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010460a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010460f:	80 39 30             	cmpb   $0x30,(%ecx)
f0104612:	75 08                	jne    f010461c <strtol+0x6e>
		s++, base = 8;
f0104614:	83 c1 01             	add    $0x1,%ecx
f0104617:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010461c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104621:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104624:	0f b6 11             	movzbl (%ecx),%edx
f0104627:	8d 72 d0             	lea    -0x30(%edx),%esi
f010462a:	89 f3                	mov    %esi,%ebx
f010462c:	80 fb 09             	cmp    $0x9,%bl
f010462f:	77 08                	ja     f0104639 <strtol+0x8b>
			dig = *s - '0';
f0104631:	0f be d2             	movsbl %dl,%edx
f0104634:	83 ea 30             	sub    $0x30,%edx
f0104637:	eb 22                	jmp    f010465b <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0104639:	8d 72 9f             	lea    -0x61(%edx),%esi
f010463c:	89 f3                	mov    %esi,%ebx
f010463e:	80 fb 19             	cmp    $0x19,%bl
f0104641:	77 08                	ja     f010464b <strtol+0x9d>
			dig = *s - 'a' + 10;
f0104643:	0f be d2             	movsbl %dl,%edx
f0104646:	83 ea 57             	sub    $0x57,%edx
f0104649:	eb 10                	jmp    f010465b <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010464b:	8d 72 bf             	lea    -0x41(%edx),%esi
f010464e:	89 f3                	mov    %esi,%ebx
f0104650:	80 fb 19             	cmp    $0x19,%bl
f0104653:	77 16                	ja     f010466b <strtol+0xbd>
			dig = *s - 'A' + 10;
f0104655:	0f be d2             	movsbl %dl,%edx
f0104658:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010465b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010465e:	7d 0b                	jge    f010466b <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0104660:	83 c1 01             	add    $0x1,%ecx
f0104663:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104667:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0104669:	eb b9                	jmp    f0104624 <strtol+0x76>

	if (endptr)
f010466b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010466f:	74 0d                	je     f010467e <strtol+0xd0>
		*endptr = (char *) s;
f0104671:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104674:	89 0e                	mov    %ecx,(%esi)
f0104676:	eb 06                	jmp    f010467e <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104678:	85 db                	test   %ebx,%ebx
f010467a:	74 98                	je     f0104614 <strtol+0x66>
f010467c:	eb 9e                	jmp    f010461c <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010467e:	89 c2                	mov    %eax,%edx
f0104680:	f7 da                	neg    %edx
f0104682:	85 ff                	test   %edi,%edi
f0104684:	0f 45 c2             	cmovne %edx,%eax
}
f0104687:	5b                   	pop    %ebx
f0104688:	5e                   	pop    %esi
f0104689:	5f                   	pop    %edi
f010468a:	5d                   	pop    %ebp
f010468b:	c3                   	ret    
f010468c:	66 90                	xchg   %ax,%ax
f010468e:	66 90                	xchg   %ax,%ax

f0104690 <__udivdi3>:
f0104690:	55                   	push   %ebp
f0104691:	57                   	push   %edi
f0104692:	56                   	push   %esi
f0104693:	53                   	push   %ebx
f0104694:	83 ec 1c             	sub    $0x1c,%esp
f0104697:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010469b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010469f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01046a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01046a7:	85 f6                	test   %esi,%esi
f01046a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01046ad:	89 ca                	mov    %ecx,%edx
f01046af:	89 f8                	mov    %edi,%eax
f01046b1:	75 3d                	jne    f01046f0 <__udivdi3+0x60>
f01046b3:	39 cf                	cmp    %ecx,%edi
f01046b5:	0f 87 c5 00 00 00    	ja     f0104780 <__udivdi3+0xf0>
f01046bb:	85 ff                	test   %edi,%edi
f01046bd:	89 fd                	mov    %edi,%ebp
f01046bf:	75 0b                	jne    f01046cc <__udivdi3+0x3c>
f01046c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01046c6:	31 d2                	xor    %edx,%edx
f01046c8:	f7 f7                	div    %edi
f01046ca:	89 c5                	mov    %eax,%ebp
f01046cc:	89 c8                	mov    %ecx,%eax
f01046ce:	31 d2                	xor    %edx,%edx
f01046d0:	f7 f5                	div    %ebp
f01046d2:	89 c1                	mov    %eax,%ecx
f01046d4:	89 d8                	mov    %ebx,%eax
f01046d6:	89 cf                	mov    %ecx,%edi
f01046d8:	f7 f5                	div    %ebp
f01046da:	89 c3                	mov    %eax,%ebx
f01046dc:	89 d8                	mov    %ebx,%eax
f01046de:	89 fa                	mov    %edi,%edx
f01046e0:	83 c4 1c             	add    $0x1c,%esp
f01046e3:	5b                   	pop    %ebx
f01046e4:	5e                   	pop    %esi
f01046e5:	5f                   	pop    %edi
f01046e6:	5d                   	pop    %ebp
f01046e7:	c3                   	ret    
f01046e8:	90                   	nop
f01046e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01046f0:	39 ce                	cmp    %ecx,%esi
f01046f2:	77 74                	ja     f0104768 <__udivdi3+0xd8>
f01046f4:	0f bd fe             	bsr    %esi,%edi
f01046f7:	83 f7 1f             	xor    $0x1f,%edi
f01046fa:	0f 84 98 00 00 00    	je     f0104798 <__udivdi3+0x108>
f0104700:	bb 20 00 00 00       	mov    $0x20,%ebx
f0104705:	89 f9                	mov    %edi,%ecx
f0104707:	89 c5                	mov    %eax,%ebp
f0104709:	29 fb                	sub    %edi,%ebx
f010470b:	d3 e6                	shl    %cl,%esi
f010470d:	89 d9                	mov    %ebx,%ecx
f010470f:	d3 ed                	shr    %cl,%ebp
f0104711:	89 f9                	mov    %edi,%ecx
f0104713:	d3 e0                	shl    %cl,%eax
f0104715:	09 ee                	or     %ebp,%esi
f0104717:	89 d9                	mov    %ebx,%ecx
f0104719:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010471d:	89 d5                	mov    %edx,%ebp
f010471f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104723:	d3 ed                	shr    %cl,%ebp
f0104725:	89 f9                	mov    %edi,%ecx
f0104727:	d3 e2                	shl    %cl,%edx
f0104729:	89 d9                	mov    %ebx,%ecx
f010472b:	d3 e8                	shr    %cl,%eax
f010472d:	09 c2                	or     %eax,%edx
f010472f:	89 d0                	mov    %edx,%eax
f0104731:	89 ea                	mov    %ebp,%edx
f0104733:	f7 f6                	div    %esi
f0104735:	89 d5                	mov    %edx,%ebp
f0104737:	89 c3                	mov    %eax,%ebx
f0104739:	f7 64 24 0c          	mull   0xc(%esp)
f010473d:	39 d5                	cmp    %edx,%ebp
f010473f:	72 10                	jb     f0104751 <__udivdi3+0xc1>
f0104741:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104745:	89 f9                	mov    %edi,%ecx
f0104747:	d3 e6                	shl    %cl,%esi
f0104749:	39 c6                	cmp    %eax,%esi
f010474b:	73 07                	jae    f0104754 <__udivdi3+0xc4>
f010474d:	39 d5                	cmp    %edx,%ebp
f010474f:	75 03                	jne    f0104754 <__udivdi3+0xc4>
f0104751:	83 eb 01             	sub    $0x1,%ebx
f0104754:	31 ff                	xor    %edi,%edi
f0104756:	89 d8                	mov    %ebx,%eax
f0104758:	89 fa                	mov    %edi,%edx
f010475a:	83 c4 1c             	add    $0x1c,%esp
f010475d:	5b                   	pop    %ebx
f010475e:	5e                   	pop    %esi
f010475f:	5f                   	pop    %edi
f0104760:	5d                   	pop    %ebp
f0104761:	c3                   	ret    
f0104762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104768:	31 ff                	xor    %edi,%edi
f010476a:	31 db                	xor    %ebx,%ebx
f010476c:	89 d8                	mov    %ebx,%eax
f010476e:	89 fa                	mov    %edi,%edx
f0104770:	83 c4 1c             	add    $0x1c,%esp
f0104773:	5b                   	pop    %ebx
f0104774:	5e                   	pop    %esi
f0104775:	5f                   	pop    %edi
f0104776:	5d                   	pop    %ebp
f0104777:	c3                   	ret    
f0104778:	90                   	nop
f0104779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104780:	89 d8                	mov    %ebx,%eax
f0104782:	f7 f7                	div    %edi
f0104784:	31 ff                	xor    %edi,%edi
f0104786:	89 c3                	mov    %eax,%ebx
f0104788:	89 d8                	mov    %ebx,%eax
f010478a:	89 fa                	mov    %edi,%edx
f010478c:	83 c4 1c             	add    $0x1c,%esp
f010478f:	5b                   	pop    %ebx
f0104790:	5e                   	pop    %esi
f0104791:	5f                   	pop    %edi
f0104792:	5d                   	pop    %ebp
f0104793:	c3                   	ret    
f0104794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104798:	39 ce                	cmp    %ecx,%esi
f010479a:	72 0c                	jb     f01047a8 <__udivdi3+0x118>
f010479c:	31 db                	xor    %ebx,%ebx
f010479e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01047a2:	0f 87 34 ff ff ff    	ja     f01046dc <__udivdi3+0x4c>
f01047a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01047ad:	e9 2a ff ff ff       	jmp    f01046dc <__udivdi3+0x4c>
f01047b2:	66 90                	xchg   %ax,%ax
f01047b4:	66 90                	xchg   %ax,%ax
f01047b6:	66 90                	xchg   %ax,%ax
f01047b8:	66 90                	xchg   %ax,%ax
f01047ba:	66 90                	xchg   %ax,%ax
f01047bc:	66 90                	xchg   %ax,%ax
f01047be:	66 90                	xchg   %ax,%ax

f01047c0 <__umoddi3>:
f01047c0:	55                   	push   %ebp
f01047c1:	57                   	push   %edi
f01047c2:	56                   	push   %esi
f01047c3:	53                   	push   %ebx
f01047c4:	83 ec 1c             	sub    $0x1c,%esp
f01047c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01047cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01047cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01047d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01047d7:	85 d2                	test   %edx,%edx
f01047d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01047dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047e1:	89 f3                	mov    %esi,%ebx
f01047e3:	89 3c 24             	mov    %edi,(%esp)
f01047e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01047ea:	75 1c                	jne    f0104808 <__umoddi3+0x48>
f01047ec:	39 f7                	cmp    %esi,%edi
f01047ee:	76 50                	jbe    f0104840 <__umoddi3+0x80>
f01047f0:	89 c8                	mov    %ecx,%eax
f01047f2:	89 f2                	mov    %esi,%edx
f01047f4:	f7 f7                	div    %edi
f01047f6:	89 d0                	mov    %edx,%eax
f01047f8:	31 d2                	xor    %edx,%edx
f01047fa:	83 c4 1c             	add    $0x1c,%esp
f01047fd:	5b                   	pop    %ebx
f01047fe:	5e                   	pop    %esi
f01047ff:	5f                   	pop    %edi
f0104800:	5d                   	pop    %ebp
f0104801:	c3                   	ret    
f0104802:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104808:	39 f2                	cmp    %esi,%edx
f010480a:	89 d0                	mov    %edx,%eax
f010480c:	77 52                	ja     f0104860 <__umoddi3+0xa0>
f010480e:	0f bd ea             	bsr    %edx,%ebp
f0104811:	83 f5 1f             	xor    $0x1f,%ebp
f0104814:	75 5a                	jne    f0104870 <__umoddi3+0xb0>
f0104816:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010481a:	0f 82 e0 00 00 00    	jb     f0104900 <__umoddi3+0x140>
f0104820:	39 0c 24             	cmp    %ecx,(%esp)
f0104823:	0f 86 d7 00 00 00    	jbe    f0104900 <__umoddi3+0x140>
f0104829:	8b 44 24 08          	mov    0x8(%esp),%eax
f010482d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104831:	83 c4 1c             	add    $0x1c,%esp
f0104834:	5b                   	pop    %ebx
f0104835:	5e                   	pop    %esi
f0104836:	5f                   	pop    %edi
f0104837:	5d                   	pop    %ebp
f0104838:	c3                   	ret    
f0104839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104840:	85 ff                	test   %edi,%edi
f0104842:	89 fd                	mov    %edi,%ebp
f0104844:	75 0b                	jne    f0104851 <__umoddi3+0x91>
f0104846:	b8 01 00 00 00       	mov    $0x1,%eax
f010484b:	31 d2                	xor    %edx,%edx
f010484d:	f7 f7                	div    %edi
f010484f:	89 c5                	mov    %eax,%ebp
f0104851:	89 f0                	mov    %esi,%eax
f0104853:	31 d2                	xor    %edx,%edx
f0104855:	f7 f5                	div    %ebp
f0104857:	89 c8                	mov    %ecx,%eax
f0104859:	f7 f5                	div    %ebp
f010485b:	89 d0                	mov    %edx,%eax
f010485d:	eb 99                	jmp    f01047f8 <__umoddi3+0x38>
f010485f:	90                   	nop
f0104860:	89 c8                	mov    %ecx,%eax
f0104862:	89 f2                	mov    %esi,%edx
f0104864:	83 c4 1c             	add    $0x1c,%esp
f0104867:	5b                   	pop    %ebx
f0104868:	5e                   	pop    %esi
f0104869:	5f                   	pop    %edi
f010486a:	5d                   	pop    %ebp
f010486b:	c3                   	ret    
f010486c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104870:	8b 34 24             	mov    (%esp),%esi
f0104873:	bf 20 00 00 00       	mov    $0x20,%edi
f0104878:	89 e9                	mov    %ebp,%ecx
f010487a:	29 ef                	sub    %ebp,%edi
f010487c:	d3 e0                	shl    %cl,%eax
f010487e:	89 f9                	mov    %edi,%ecx
f0104880:	89 f2                	mov    %esi,%edx
f0104882:	d3 ea                	shr    %cl,%edx
f0104884:	89 e9                	mov    %ebp,%ecx
f0104886:	09 c2                	or     %eax,%edx
f0104888:	89 d8                	mov    %ebx,%eax
f010488a:	89 14 24             	mov    %edx,(%esp)
f010488d:	89 f2                	mov    %esi,%edx
f010488f:	d3 e2                	shl    %cl,%edx
f0104891:	89 f9                	mov    %edi,%ecx
f0104893:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104897:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010489b:	d3 e8                	shr    %cl,%eax
f010489d:	89 e9                	mov    %ebp,%ecx
f010489f:	89 c6                	mov    %eax,%esi
f01048a1:	d3 e3                	shl    %cl,%ebx
f01048a3:	89 f9                	mov    %edi,%ecx
f01048a5:	89 d0                	mov    %edx,%eax
f01048a7:	d3 e8                	shr    %cl,%eax
f01048a9:	89 e9                	mov    %ebp,%ecx
f01048ab:	09 d8                	or     %ebx,%eax
f01048ad:	89 d3                	mov    %edx,%ebx
f01048af:	89 f2                	mov    %esi,%edx
f01048b1:	f7 34 24             	divl   (%esp)
f01048b4:	89 d6                	mov    %edx,%esi
f01048b6:	d3 e3                	shl    %cl,%ebx
f01048b8:	f7 64 24 04          	mull   0x4(%esp)
f01048bc:	39 d6                	cmp    %edx,%esi
f01048be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01048c2:	89 d1                	mov    %edx,%ecx
f01048c4:	89 c3                	mov    %eax,%ebx
f01048c6:	72 08                	jb     f01048d0 <__umoddi3+0x110>
f01048c8:	75 11                	jne    f01048db <__umoddi3+0x11b>
f01048ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01048ce:	73 0b                	jae    f01048db <__umoddi3+0x11b>
f01048d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01048d4:	1b 14 24             	sbb    (%esp),%edx
f01048d7:	89 d1                	mov    %edx,%ecx
f01048d9:	89 c3                	mov    %eax,%ebx
f01048db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01048df:	29 da                	sub    %ebx,%edx
f01048e1:	19 ce                	sbb    %ecx,%esi
f01048e3:	89 f9                	mov    %edi,%ecx
f01048e5:	89 f0                	mov    %esi,%eax
f01048e7:	d3 e0                	shl    %cl,%eax
f01048e9:	89 e9                	mov    %ebp,%ecx
f01048eb:	d3 ea                	shr    %cl,%edx
f01048ed:	89 e9                	mov    %ebp,%ecx
f01048ef:	d3 ee                	shr    %cl,%esi
f01048f1:	09 d0                	or     %edx,%eax
f01048f3:	89 f2                	mov    %esi,%edx
f01048f5:	83 c4 1c             	add    $0x1c,%esp
f01048f8:	5b                   	pop    %ebx
f01048f9:	5e                   	pop    %esi
f01048fa:	5f                   	pop    %edi
f01048fb:	5d                   	pop    %ebp
f01048fc:	c3                   	ret    
f01048fd:	8d 76 00             	lea    0x0(%esi),%esi
f0104900:	29 f9                	sub    %edi,%ecx
f0104902:	19 d6                	sbb    %edx,%esi
f0104904:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104908:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010490c:	e9 18 ff ff ff       	jmp    f0104829 <__umoddi3+0x69>
