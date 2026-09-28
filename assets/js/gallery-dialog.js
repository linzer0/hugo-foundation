const dialog = document.querySelector("[data-gallery-dialog]");

if (dialog) {
    const image = dialog.querySelector("[data-gallery-dialog-image]");
    const caption = dialog.querySelector("[data-gallery-dialog-caption]");
    const closeButton = dialog.querySelector("[data-gallery-dialog-close]");
    let trigger = null;

    document.querySelectorAll("[data-gallery-image]").forEach((link) => {
        link.addEventListener("click", (event) => {
            if (!dialog.showModal) {
                return;
            }

            event.preventDefault();
            trigger = link;
            image.src = link.href;
            image.alt = link.dataset.galleryAlt || "";
            caption.textContent = link.dataset.galleryAlt || "";
            dialog.showModal();
            closeButton.focus();
        });
    });

    const closeDialog = () => {
        if (dialog.open) {
            dialog.close();
        }
    };

    dialog.addEventListener("close", () => {
        image.removeAttribute("src");
        if (trigger) {
            trigger.focus();
            trigger = null;
        }
    });

    dialog.addEventListener("cancel", (event) => {
        event.preventDefault();
        closeDialog();
    });

    closeButton.addEventListener("click", closeDialog);
    dialog.addEventListener("click", (event) => {
        if (event.target === dialog) {
            closeDialog();
        }
    });
}