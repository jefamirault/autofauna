// app/javascript/controllers/sidebar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["toggleButton"]
    static classes = ["minimized"]
    static values = {
        minimized: Boolean
    }

    connect() {
        // Set initial state based on stored preference or default
        const stored = localStorage.getItem('sidebar-minimized')
        const isMobile = window.innerWidth < 600
        this.minimizedValue = isMobile || (stored ? JSON.parse(stored) : false)
        this.updateSidebar()

        this.handleResize = this.handleResize.bind(this)
        window.addEventListener('resize', this.handleResize)

        // Initialize scroll handling for mobile
        this.lastScrollTop = 0
        this.handleScroll = this.handleScroll.bind(this)
        const main = document.querySelector('main')
        if (main) {
            main.addEventListener('scroll', this.handleScroll, { passive: true })
        }

        // Initialize touch handling
        this.initializeTouchHandling()

        // Mobile: detect downward swipe on sidebar itself to minimize
        this.handleSidebarTouchStart = this.handleSidebarTouchStart.bind(this)
        this.handleSidebarTouchEnd = this.handleSidebarTouchEnd.bind(this)
        const sidebar = document.getElementById('sidebar')
        if (sidebar && window.innerWidth < 600) {
            sidebar.addEventListener('touchstart', this.handleSidebarTouchStart, { passive: true })
            sidebar.addEventListener('touchend', this.handleSidebarTouchEnd, { passive: true })
        }

        // Re-enable transitions after initial state is applied
        requestAnimationFrame(() => {
            document.documentElement.classList.remove('no-transition')
        })
    }

    disconnect() {
        window.removeEventListener('resize', this.handleResize)
        const main = document.querySelector('main')
        if (main) {
            main.removeEventListener('scroll', this.handleScroll)
        }
        this.removeTouchHandling()
        const sidebar = document.getElementById('sidebar')
        if (sidebar) {
            sidebar.removeEventListener('touchstart', this.handleSidebarTouchStart)
            sidebar.removeEventListener('touchend', this.handleSidebarTouchEnd)
        }
    }

    handleSidebarTouchStart(e) {
        this.sidebarTouchStartY = e.touches[0].clientY
    }

    handleSidebarTouchEnd(e) {
        const deltaY = this.sidebarTouchStartY - e.changedTouches[0].clientY
        if (deltaY >= 30) {
            this.closeOnMobile()
        }
    }

    handleScroll(e) {
        const scrollTop = e.target.scrollTop
        if (window.innerWidth < 600 && !this.minimizedValue && scrollTop > this.lastScrollTop) {
            this.closeOnMobile()
        }
        this.lastScrollTop = scrollTop
    }

    handleResize() {
        if (window.innerWidth < 600 && !this.minimizedValue) {
            this.minimizedValue = true
            this.updateSidebar()
        }
    }

    initializeTouchHandling() {
        this.touchStartX = 0
        this.touchStartY = 0
        this.touchEndX = 0
        this.touchEndY = 0
        this.minSwipeDistance = 50
        this.maxCrossAxisDistance = 100
        this.isTracking = false

        // Bind methods to preserve context
        this.handleTouchStart = this.handleTouchStart.bind(this)
        this.handleTouchMove = this.handleTouchMove.bind(this)
        this.handleTouchEnd = this.handleTouchEnd.bind(this)

        // Add touch event listeners
        document.addEventListener('touchstart', this.handleTouchStart, { passive: true })
        document.addEventListener('touchmove', this.handleTouchMove, { passive: false })
        document.addEventListener('touchend', this.handleTouchEnd, { passive: true })
    }

    removeTouchHandling() {
        document.removeEventListener('touchstart', this.handleTouchStart)
        document.removeEventListener('touchmove', this.handleTouchMove)
        document.removeEventListener('touchend', this.handleTouchEnd)
    }

    handleTouchStart(e) {
        this.touchStartX = e.touches[0].clientX
        this.touchStartY = e.touches[0].clientY
        this.isTracking = false

        const isNarrowScreen = window.innerWidth < 600

        if (!isNarrowScreen) {
            // Different detection areas based on sidebar state
            if (this.minimizedValue) {
                // Sidebar is minimized - use left 15% of screen for expanding
                const leftEdgeThreshold = window.innerWidth * 0.15
                if (this.touchStartX <= leftEdgeThreshold) {
                    this.isTracking = true
                }
            } else {
                // Sidebar is expanded - only detect swipes within the sidebar area for minimizing
                const sidebarWidth = 18 * parseFloat(getComputedStyle(document.documentElement).fontSize) // 18rem in pixels
                if (this.touchStartX <= sidebarWidth * 1.2) { // extra 10% grabbable area
                    this.isTracking = true
                }
            }
        }
    }

    handleTouchMove(e) {
        if (!this.isTracking) return

        const currentX = e.touches[0].clientX
        const currentY = e.touches[0].clientY
        const deltaX = currentX - this.touchStartX
        const deltaY = currentY - this.touchStartY

        // Only handle horizontal swipes for wide screens
        if (Math.abs(deltaX) > 10 && Math.abs(deltaX) > Math.abs(deltaY)) {
            // This looks like a horizontal swipe
            e.preventDefault()
        }
    }

    handleTouchEnd(e) {
        if (!this.isTracking) return

        this.touchEndX = e.changedTouches[0].clientX
        this.touchEndY = e.changedTouches[0].clientY
        this.handleSwipe()
    }

    handleSwipe() {
        const isNarrowScreen = window.innerWidth < 600

        // Only handle swipes on wide screens
        if (!isNarrowScreen) {
            // Handle horizontal swipes for wide screens (sidebar at left)
            const horizontalDistance = this.touchEndX - this.touchStartX
            const verticalDistance = Math.abs(this.touchEndY - this.touchStartY)

            // Only process horizontal swipes that don't have too much vertical movement
            if (verticalDistance > this.maxCrossAxisDistance) return

            // Check if swipe distance meets minimum threshold
            if (Math.abs(horizontalDistance) < this.minSwipeDistance) return

            // Swipe right (expand sidebar) - only if sidebar is minimized
            if (horizontalDistance > 0 && this.minimizedValue) {
                this.minimizedValue = false
                this.updateSidebar()
                localStorage.setItem('sidebar-minimized', JSON.stringify(this.minimizedValue))
            }

            // Swipe left (minimize sidebar) - only if sidebar is expanded
            if (horizontalDistance < 0 && !this.minimizedValue) {
                this.minimizedValue = true
                this.updateSidebar()
                localStorage.setItem('sidebar-minimized', JSON.stringify(this.minimizedValue))
            }
        }
    }

    toggle() {
        this.minimizedValue = !this.minimizedValue
        this.updateSidebar()

        // Store preference
        localStorage.setItem('sidebar-minimized', JSON.stringify(this.minimizedValue))
    }

    closeOnMobile() {
        const isMobile = window.innerWidth < 600
        if (isMobile && !this.minimizedValue) {
            this.minimizedValue = true
            this.updateSidebar()
            localStorage.setItem('sidebar-minimized', JSON.stringify(this.minimizedValue))
        }
    }

    handleNavClick() {
        const isMobile = window.innerWidth < 600
        if (isMobile && !this.minimizedValue) {
            // Mobile expanded: minimize on nav click (existing closeOnMobile behavior)
            this.minimizedValue = true
            this.updateSidebar()
            localStorage.setItem('sidebar-minimized', JSON.stringify(this.minimizedValue))
        } else if (!isMobile && this.minimizedValue) {
            // Desktop minimized (icon rail): expand on nav click
            this.minimizedValue = false
            this.updateSidebar()
            localStorage.setItem('sidebar-minimized', JSON.stringify(this.minimizedValue))
        }
    }

    updateSidebar() {
        const button = this.toggleButtonTarget
        const body = document.body
        const html = document.documentElement

        if (this.minimizedValue) {
            // Minimize sidebar - add class to body for grid layout change
            body.classList.add(...this.minimizedClasses)
            html.classList.add(...this.minimizedClasses)
            button.setAttribute('aria-label', 'Expand sidebar')
        } else {
            // Maximize sidebar - remove class from body
            body.classList.remove(...this.minimizedClasses)
            html.classList.remove(...this.minimizedClasses)
            button.setAttribute('aria-label', 'Collapse sidebar')
        }
    }

}