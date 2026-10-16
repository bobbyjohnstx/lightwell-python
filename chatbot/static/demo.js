(function () {
    "use strict";

    /* ── State ───────────────────────────────────────────────── */

    var currentStep = 1;
    var totalSteps = 8;

    /* ── DOM References ──────────────────────────────────────── */

    var stepItems = document.querySelectorAll(".step-item");
    var stepPanels = document.querySelectorAll(".step-panel");
    var stepContent = document.getElementById("stepContent");
    var btnRestart = document.getElementById("btnRestart");

    /* ── Navigation ──────────────────────────────────────────── */

    function goToStep(step) {
        if (step < 1 || step > totalSteps || step === currentStep) {
            return;
        }

        // Update step dots
        stepItems.forEach(function (item) {
            var itemStep = parseInt(item.getAttribute("data-step"), 10);
            item.classList.remove("active");
            item.setAttribute("aria-selected", "false");
            item.setAttribute("tabindex", "-1");

            if (itemStep < step) {
                item.classList.add("completed");
            } else {
                item.classList.remove("completed");
            }
        });

        // Activate current step dot
        var activeItem = document.querySelector(
            '.step-item[data-step="' + step + '"]'
        );
        if (activeItem) {
            activeItem.classList.add("active");
            activeItem.classList.remove("completed");
            activeItem.setAttribute("aria-selected", "true");
            activeItem.setAttribute("tabindex", "0");
        }

        // Switch panels
        stepPanels.forEach(function (panel) {
            panel.classList.remove("active");
        });

        var activePanel = document.querySelector(
            '.step-panel[data-step="' + step + '"]'
        );
        if (activePanel) {
            activePanel.classList.add("active");
        }

        // Scroll content to top
        if (stepContent) {
            stepContent.scrollTop = 0;
        }

        currentStep = step;
    }

    function nextStep() {
        goToStep(currentStep + 1);
    }

    function prevStep() {
        goToStep(currentStep - 1);
    }

    function restart() {
        stepItems.forEach(function (item) {
            item.classList.remove("completed");
        });
        currentStep = 0;
        goToStep(1);
    }

    /* ── Event Listeners: Step Dots ───────────────────────────── */

    stepItems.forEach(function (item) {
        item.addEventListener("click", function () {
            var step = parseInt(this.getAttribute("data-step"), 10);
            goToStep(step);
        });

        item.addEventListener("keydown", function (e) {
            if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                var step = parseInt(this.getAttribute("data-step"), 10);
                goToStep(step);
            }

            // Navigate between dots with arrow keys
            var allItems = Array.prototype.slice.call(stepItems);
            var idx = allItems.indexOf(this);

            if (e.key === "ArrowRight" || e.key === "ArrowDown") {
                e.preventDefault();
                if (idx < allItems.length - 1) {
                    allItems[idx + 1].focus();
                }
            }

            if (e.key === "ArrowLeft" || e.key === "ArrowUp") {
                e.preventDefault();
                if (idx > 0) {
                    allItems[idx - 1].focus();
                }
            }
        });
    });

    /* ── Event Listeners: Next/Prev/Restart Buttons ──────────── */

    document.querySelectorAll(".btn-next").forEach(function (btn) {
        btn.addEventListener("click", function () {
            var target = parseInt(this.getAttribute("data-next"), 10);
            goToStep(target);
        });
    });

    document.querySelectorAll(".btn-prev").forEach(function (btn) {
        btn.addEventListener("click", function () {
            var target = parseInt(this.getAttribute("data-prev"), 10);
            goToStep(target);
        });
    });

    if (btnRestart) {
        btnRestart.addEventListener("click", restart);
    }

    /* ── Keyboard Navigation (global) ────────────────────────── */

    document.addEventListener("keydown", function (e) {
        // Ignore if user is in an input or focused on a step dot
        if (
            e.target.tagName === "INPUT" ||
            e.target.tagName === "TEXTAREA" ||
            e.target.isContentEditable ||
            e.target.closest(".step-dots")
        ) {
            return;
        }

        switch (e.key) {
            case "ArrowRight":
            case "PageDown":
                e.preventDefault();
                nextStep();
                break;

            case "ArrowLeft":
            case "PageUp":
                e.preventDefault();
                prevStep();
                break;

            case "Home":
                e.preventDefault();
                goToStep(1);
                break;

            case "End":
                e.preventDefault();
                goToStep(totalSteps);
                break;
        }
    });

    /* ── Touch Swipe (mobile) ────────────────────────────────── */

    var touchStartX = 0;
    var swipeThreshold = 60;

    if (stepContent) {
        stepContent.addEventListener(
            "touchstart",
            function (e) {
                touchStartX = e.changedTouches[0].screenX;
            },
            { passive: true }
        );

        stepContent.addEventListener(
            "touchend",
            function (e) {
                var diff = touchStartX - e.changedTouches[0].screenX;
                if (Math.abs(diff) > swipeThreshold) {
                    if (diff > 0) {
                        nextStep();
                    } else {
                        prevStep();
                    }
                }
            },
            { passive: true }
        );
    }
})();
