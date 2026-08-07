import { useState, useCallback, useRef, useEffect } from 'react'

/* ═══════════════════════════════════════
   SVG Icons — bespoke to bubblewrap
   ═══════════════════════════════════════ */

// A minimalist trackpad interaction
function IconFingerPress() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="6" width="20" height="12" rx="2" />
      <path d="M12 11v6" />
      <circle cx="12" cy="11" r="2" />
    </svg>
  )
}

// A minimalist haptic wave / pulse
function IconHapticPulse() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4a8 8 0 0 1 8 8 8 8 0 0 1-8 8" opacity="0.3" />
      <path d="M12 8a4 4 0 0 1 4 4 4 4 0 0 1-4 4" opacity="0.6" />
      <circle cx="12" cy="12" r="1.5" fill="currentColor" />
    </svg>
  )
}

// Minimalist physics/deformation (drop squish)
function IconBubbleSquish() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3v6" />
      <path d="M9 6l3 3 3-3" />
      <ellipse cx="12" cy="17" rx="8" ry="4" opacity="0.8" />
      <ellipse cx="12" cy="17" rx="4" ry="2" opacity="0.4" />
    </svg>
  )
}

// Minimalist menu bar / native app
function IconMenuBarTray() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="18" height="16" rx="2" />
      <path d="M3 8h18" />
      <circle cx="17" cy="6" r="1" fill="currentColor" />
    </svg>
  )
}

function AppleLogo() {
  return (
    <svg width="18" height="22" viewBox="0 0 384 512" fill="currentColor">
      <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/>
    </svg>
  )
}

/* ═══════════════════════════════════════
   Scroll reveal hook
   ═══════════════════════════════════════ */
function useReveal(threshold = 0.12) {
  const ref = useRef(null)
  useEffect(() => {
    const el = ref.current
    if (!el) return
    const obs = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { el.classList.add('in'); obs.disconnect() } },
      { threshold }
    )
    obs.observe(el)
    return () => obs.disconnect()
  }, [threshold])
  return ref
}

/* ═══════════════════════════════════════
   Hero Bubble
   ═══════════════════════════════════════ */
function HeroBubble() {
  const [popped, setPopped] = useState(false)
  const [particles, setParticles] = useState([])
  const [ripple, setRipple] = useState(false)

  const pop = useCallback(() => {
    if (popped) return
    setPopped(true)
    setRipple(true)

    if (typeof navigator !== 'undefined' && navigator.vibrate) {
      navigator.vibrate(30)
    }

    setParticles(
      Array.from({ length: 10 }, (_, i) => {
        const a = (i / 10) * Math.PI * 2
        const d = 50 + Math.random() * 30
        return { id: i, tx: Math.cos(a) * d, ty: Math.sin(a) * d }
      })
    )

    setTimeout(() => { setParticles([]); setRipple(false) }, 550)
    setTimeout(() => setPopped(false), 2200)
  }, [popped])

  return (
    <div className="relative inline-block">
      <div className={`hero-bubble ${popped ? 'popped' : ''}`} onClick={pop}>
        <div className="body"><div className="spec" /></div>
        {ripple && <div className="ripple" />}
        {particles.map(p => (
          <div key={p.id} className="burst"
            style={{ '--tx': `${p.tx}px`, '--ty': `${p.ty}px`, left: '50%', top: '50%' }} />
        ))}
      </div>
      {!popped && (
        <span className="hero-bubble-hint">press me</span>
      )}
    </div>
  )
}

/* ═══════════════════════════════════════
   Bubble Grid
   ═══════════════════════════════════════ */
function BubbleGrid() {
  const COLS = 8
  const ROWS = 5
  const TOTAL = COLS * ROWS
  const [bubbles, setBubbles] = useState(() =>
    Array.from({ length: TOTAL }, (_, i) => ({ id: i, popped: false }))
  )
  const [pops, setPops] = useState(0)

  const pop = useCallback((id) => {
    setBubbles(prev => prev.map(b => b.id === id && !b.popped ? { ...b, popped: true } : b))
    setPops(c => c + 1)
    
    if (typeof navigator !== 'undefined' && navigator.vibrate) {
      navigator.vibrate(20)
    }
  }, [])

  const allPopped = bubbles.every(b => b.popped)

  useEffect(() => {
    if (!allPopped) return
    const t = setTimeout(() => {
      setBubbles(Array.from({ length: TOTAL }, (_, i) => ({ id: i, popped: false })))
    }, 1000)
    return () => clearTimeout(t)
  }, [allPopped])

  return (
    <div className="glass playground-card w-full max-w-[400px]">
      <div className="flex flex-col items-center justify-center mb-6">
        <p className="text-sm text-text-secondary mb-2">Pop them all.</p>
        <div className="flex items-baseline gap-2">
          <span className="text-2xl font-extralight text-accent tabular-nums">{pops}</span>
          <span className="text-[10px] text-text-tertiary uppercase tracking-[2px]">pops</span>
        </div>
      </div>
      <div className="grid gap-[6px]" style={{ gridTemplateColumns: `repeat(${COLS}, 1fr)` }}>
        {bubbles.map(b => (
          <div key={b.id} className={`mini-b ${b.popped ? 'pop' : ''}`}
            onClick={() => !b.popped && pop(b.id)} />
        ))}
      </div>
    </div>
  )
}

/* ═══════════════════════════════════════
   Features
   ═══════════════════════════════════════ */
const features = [
  {
    Icon: IconFingerPress,
    variant: 'touch',
    title: 'Your Trackpad Is the Wrap',
    desc: 'Press down on your Mac trackpad and feel each bubble pop under your finger.',
  },
  {
    Icon: IconHapticPulse,
    variant: 'haptic',
    title: 'Taptic Engine Feedback',
    desc: "Real haptic clicks through Apple's Force Touch — not vibration, actual tactile snaps.",
  },
  {
    Icon: IconBubbleSquish,
    variant: 'physics',
    title: 'Liquid Deformation',
    desc: 'Bubbles squish and stretch under pressure before they burst. Built with native AppKit.',
  },
  {
    Icon: IconMenuBarTray,
    variant: 'native',
    title: 'Lives in Your Menu Bar',
    desc: 'A lightweight native utility. Drop it down when you need it. No dock icon, no Electron.',
  },
]

/* ═══════════════════════════════════════
   Navbar
   ═══════════════════════════════════════ */
function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 30)
    window.addEventListener('scroll', fn, { passive: true })
    return () => window.removeEventListener('scroll', fn)
  }, [])

  const links = [
    { label: 'Features', href: '#features' },
    { label: 'Try It', href: '#playground' },
    { label: 'Download', href: '#download' },
  ]

  return (
    <nav className={`nav-bar ${scrolled ? 'nav-scrolled' : ''}`}>
      <div className="nav-inner">
        <a href="#" className="nav-brand">
          <img src="/bubblewrap-menubar-icon.png" alt="Logo" className="w-[18px] h-[18px] opacity-90" />
          <span className="nav-brand-text">bubblewrap</span>
        </a>

        {/* Desktop links */}
        <div className="nav-links">
          {links.map(l => (
            <a key={l.label} href={l.href} className="nav-link">{l.label}</a>
          ))}
          <a href="/BubbleWrap.zip" download="BubbleWrap.zip" className="nav-cta">
            <AppleLogo />
            <span>Get the App</span>
          </a>
        </div>

        {/* Mobile hamburger */}
        <button className="nav-mobile-btn" onClick={() => setMobileOpen(!mobileOpen)} aria-label="Toggle menu">
          <span className={`hamburger ${mobileOpen ? 'open' : ''}`} />
        </button>
      </div>

      {/* Mobile dropdown */}
      {mobileOpen && (
        <div className="nav-mobile-menu">
          {links.map(l => (
            <a key={l.label} href={l.href} className="nav-mobile-link" onClick={() => setMobileOpen(false)}>
              {l.label}
            </a>
          ))}
          <a href="/BubbleWrap.zip" download="BubbleWrap.zip" className="nav-mobile-link nav-mobile-cta">
            <AppleLogo /> Get the App
          </a>
        </div>
      )}
    </nav>
  )
}

/* ═══════════════════════════════════════
   Download Button (reusable)
   ═══════════════════════════════════════ */
function DownloadButton() {
  return (
    <a href="/BubbleWrap.zip" download="BubbleWrap.zip" className="cta">
      <AppleLogo />
      <div className="flex flex-col items-start text-left">
        <span className="text-[10px] text-text-tertiary uppercase tracking-[1.5px] leading-none mb-1">
          Download for
        </span>
        <span className="text-base font-semibold leading-none">
          macOS
        </span>
      </div>
    </a>
  )
}

/* ═══════════════════════════════════════
   Scroll down indicator
   ═══════════════════════════════════════ */
function ScrollHint() {
  return (
    <div className="scroll-hint">
      <svg width="20" height="32" viewBox="0 0 20 32" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
        <rect x="1" y="1" width="18" height="30" rx="9" />
        <line x1="10" y1="8" x2="10" y2="14" className="scroll-hint-dot" />
      </svg>
    </div>
  )
}

/* ═══════════════════════════════════════
   Page
   ═══════════════════════════════════════ */
export default function App() {
  const heroRef = useReveal(0.05)
  const featRef = useReveal(0.1)
  const gridRef = useReveal(0.1)
  const ctaRef = useReveal(0.1)

  return (
    <>
      <div className="bg-glow" />
      <div className="noise" />
      <Navbar />

      <main className="relative z-10 w-full max-w-5xl mx-auto px-6 sm:px-10">

        {/* ── Hero ── */}
        <section className="min-h-[100dvh] flex flex-col items-center justify-center text-center relative">
          <div ref={heroRef} className="reveal">

            <div className="mb-16">
              <HeroBubble />
            </div>

            <h1 className="text-[clamp(2.5rem,6vw,4rem)] font-bold tracking-[-0.035em] leading-[1.05] mb-7">
              <span className="bg-gradient-to-b from-white via-white/85 to-white/40 bg-clip-text text-transparent">
                Stress relief, <br />one pop at a time.
              </span>
            </h1>

            <p className="text-lg sm:text-xl text-text-secondary leading-relaxed max-w-lg mx-auto mb-12">
              Your Mac trackpad becomes bubble wrap. <br className="hidden sm:block" />
              Press down. Feel the pop. That's it.
            </p>

            <DownloadButton />
          </div>

          <ScrollHint />
        </section>

        {/* ── Features ── */}
        <section id="features" className="section-block">
          <div ref={featRef} className="reveal">

            <div className="text-center mb-16">
              <p className="section-label">Why it feels real</p>
              <h2 className="text-3xl sm:text-4xl font-semibold tracking-tight leading-tight">
                Not a gimmick.
                <br />
                <span className="text-text-secondary font-normal">An experience.</span>
              </h2>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
              {features.map(({ Icon, variant, title, desc }) => (
                <div key={title} className="feat-card glass">
                  <div className="feat-icon">
                    <Icon />
                  </div>
                  <h3 className="feat-title">{title}</h3>
                  <p className="feat-desc">{desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Interactive Playground ── */}
        <section id="playground" className="section-block section-alt">
          <div ref={gridRef} className="reveal">
            <div className="text-center mb-14">
              <p className="section-label">Try it right here</p>
              <h2 className="text-3xl sm:text-4xl font-semibold tracking-tight leading-tight">
                Go ahead.
                <br />
                <span className="text-text-secondary font-normal">You know you want to.</span>
              </h2>
            </div>

            <div className="max-w-lg mx-auto flex flex-col items-center justify-center">
              <BubbleGrid />
            </div>
          </div>
        </section>

        {/* ── Final CTA ── */}
        <section id="download" className="section-block">
          <div ref={ctaRef} className="reveal flex flex-col items-center text-center">
            <h2 className="text-3xl sm:text-4xl font-semibold tracking-tight mb-5">
              Your trackpad, but satisfying.
            </h2>
            <p className="text-base text-text-secondary mb-10 max-w-sm mx-auto leading-relaxed">
              Free. No ads. No bloat. Just bubble wrap that lives in your menu bar.
            </p>
            <DownloadButton />
          </div>
        </section>

        {/* ── Footer ── */}
        <footer className="footer">
          <div className="footer-grid">
            <div className="footer-brand">
              <span className="footer-brand-name">bubblewrap</span>
              <p className="footer-tagline">
                A native macOS menu bar app that turns your Force Touch trackpad into real bubble wrap you can feel.
              </p>
            </div>

            <div className="footer-col">
              <h4 className="footer-heading">Navigate</h4>
              <ul className="footer-links">
                <li><a href="#features">Features</a></li>
                <li><a href="#playground">Try It</a></li>
                <li><a href="#download">Download</a></li>
              </ul>
            </div>

            <div className="footer-col">
              <h4 className="footer-heading">Resources</h4>
              <ul className="footer-links">
                <li><a href="/BubbleWrap.zip" download>Download App</a></li>
                <li><a href="https://github.com/keynowawa/bubblewrap" target="_blank" rel="noopener noreferrer">GitHub</a></li>
                <li><a href="mailto:info.keyno@gmail.com">Report an Issue</a></li>
              </ul>
            </div>

            <div className="footer-col">
              <h4 className="footer-heading">Legal</h4>
              <ul className="footer-links">
                <li><a href="#">Privacy Policy</a></li>
                <li><a href="#">Terms & Conditions</a></li>
              </ul>
            </div>
          </div>

          <div className="footer-bottom">
            <span>v1.0.0 &copy; 2026 keynowawa. All rights reserved.</span>
            <span>Developed by Kyann Tagle</span>
          </div>
        </footer>
      </main>
    </>
  )
}
