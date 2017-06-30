// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW 0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.

	panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//

static void
dup_or_share(envid_t dstenv, void *va, int perm){

	//IMPL GUILLE (creo que le faltan un par de chequeos, no estoy seguro)
/*
	
	int r;
	if ((perm & PTE_W) == PTE_W ){  //Escritura: crear nueva
		//Copio directo de dumbfork. Esto deberia crear y copiar una nueva pagina.
		if ((r = sys_page_alloc(dstenv, va, perm)) < 0)
			panic("sys_page_alloc: %e", r);
		if ((r = sys_page_map(dstenv, va, 0, UTEMP, perm)) < 0)
			panic("sys_page_map: %e", r);
		memmove(UTEMP, va, PGSIZE);
		if ((r = sys_page_unmap(0, UTEMP)) < 0)
			panic("sys_page_unmap: %e", r);
	}
	else{
		//Solo lectura compartir mapeo. Compartir seria esto??
		if ((r = sys_page_map(dstenv, va, 0, va, perm)) < 0)
			panic("sys_page_map: %e", r);
	}
	return;
*/

	//IMPL MARTIN
	int r;

	if (!(perm & PTE_W)){//si es R-only solo hay que mapear
		if ((r = sys_page_map(thisenv->env_id,va,dstenv, va, perm)) < 0){//TODO: thisenv->env_id o sys_getenvid()? con env_id es directo y (luego) sin syscall que pide lock, pero no es sucio?
			panic("sys_page_map: %e", r);
		}
		return;
	}
	//si llego a aca es RW y hay que hacer el copiado

	//alloc de la pagina nueva del hijo
	if ((r = sys_page_alloc(dstenv, va, perm)) < 0){
		panic("sys_page_alloc: %e", r);
	}
	//mapeo la nueva del hijo a UTEMP en el padre
	if ((r = sys_page_map(dstenv, va, 0, UTEMP, perm)) < 0){
		panic("sys_page_map: %e", r);
	}
	//copio a la page del hijo mapeada en UTEMP del padre
	memmove(UTEMP, va, PGSIZE);

	//desmapeo del padre la page del hijo
	if ((r = sys_page_unmap(0, UTEMP)) < 0){
		panic("sys_page_unmap: %e", r);
	}
}

envid_t
fork_v0(void)
{
	// LAB 4: Your code here.
	int r;
	panic("fork not implemented");
	int pid = sys_exofork();
	if (pid < 0)
		panic("sys_exofork: %e", pid);
	if (pid == 0){
		//Hijo
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	}
	//Padre
	//Copiar mapeos

	for (uint32_t va = 0; va<UTOP; va+=PGSIZE){
		uint32_t pagen = PGNUM(va);
		uint32_t pdx = ROUNDDOWN(pagen, NPDENTRIES) / NPDENTRIES;
		if ((uvpd[pdx] & PTE_P) == PTE_P && ((uvpt[pagen] & PTE_P) == PTE_P)) {
				int perm = (uint32_t) uvpt[pagen] & PTE_SYSCALL;
				dup_or_share(pid, (void*)va, perm);
		}
	}

	//TODO: falta copiar el stack
	
	//Setear hijo como Runnable
	if ((r = sys_env_set_status(pid, ENV_RUNNABLE)) < 0)
		panic("sys_env_set_status: %e", r);

	return pid;
	
}


envid_t
fork(void){
	return fork_v0();
}


// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
