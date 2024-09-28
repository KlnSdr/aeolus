function toggleMobileMenu() {
    const mobileMenu: HTMLDivElement = document.getElementById('navBody') as HTMLDivElement;
    mobileMenu.classList.toggle("mobileMenuHidden");

    const mobileMenuButton: HTMLButtonElement = document.getElementById('bttnOpenMobileMenu') as HTMLButtonElement;
    if (mobileMenuButton.innerHTML === '☰') {
        mobileMenuButton.innerHTML = '✖';
    } else {
        mobileMenuButton.innerHTML = '☰';
    }
}