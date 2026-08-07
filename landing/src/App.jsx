import { useState, useCallback, useRef, useEffect } from 'react'

/* ═══════════════════════════════════════
   SVG Icons
   ═══════════════════════════════════════ */

function IconTrackpad() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="5" width="20" height="14" rx="3" />
      <path d="M12 19V15" opacity="0.4" />
      <circle cx="12" cy="11" r="2" fill="currentColor" opacity="0.8" />
      <path d="M12 5v2" opacity="0.4" />
    </svg>
  )
}

function IconHaptics() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="7" y="8" width="10" height="8" rx="1.5" />
      <path d="M4 12a8 8 0 0 1 0-4M4 16a8 8 0 0 0 0-8" opacity="0.3" />
      <path d="M20 12a8 8 0 0 0 0-4M20 16a8 8 0 0 1 0-8" opacity="0.3" />
      <circle cx="12" cy="12" r="1" fill="currentColor" />
    </svg>
  )
}

function IconPhysics() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 21a9 9 0 0 0 9-9c0-3-1-7-5-7-2 0-3 2-4 2s-2-2-4-2c-4 0-5 4-5 7a9 9 0 0 0 9 9z" />
      <path d="M12 21c-2 0-4-1.5-4-4s1-3.5 1-3.5" opacity="0.4" />
      <path d="M12 21c2 0 4-1.5 4-4s-1-3.5-1-3.5" opacity="0.4" />
    </svg>
  )
}

function IconMenubar() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="4" width="20" height="16" rx="2" />
      <path d="M2 9h20" opacity="0.4" />
      <circle cx="17" cy="6.5" r="1" fill="currentColor" />
      <circle cx="19" cy="6.5" r="1" fill="currentColor" />
    </svg>
  )
}

function AppleLogo() {
  return (
    <svg width="16" height="20" viewBox="0 0 18 22" fill="currentColor">
      <path d="M14.94 5.84c-.08.06-1.55.9-1.55 2.73 0 2.12 1.86 2.88 1.92 2.9-.01.05-.3 1.03-1 2.04-.6.88-1.23 1.77-2.2 1.77s-1.2-.56-2.31-.56c-1.08 0-1.47.58-2.36.58-.89 0-1.52-.82-2.21-1.82C4.21 11.89 3.5 9.6 3.5 7.45c0-3.47 2.26-5.31 4.47-5.31.88 0 1.62.58 2.18.58.52 0 1.34-.61 2.33-.61.38 0 1.72.03 2.46 1.73zM11.8.01c.08.63-.22 1.28-.6 1.74-.42.5-1.1.88-1.77.88-.1-.01-.2-.01-.22-.03-.02-.08-.03-.2-.03-.32 0-.62.26-1.28.62-1.72C10.22.1 10.93-.25 11.55-.29c.02.1.05.2.05.3h.2z" />
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
    <div className="glass p-6">
      <div className="flex items-baseline justify-between mb-5">
        <p className="text-sm text-text-secondary">Pop them all.</p>
        <div className="flex items-baseline gap-1.5">
          <span className="text-xl font-extralight text-accent tabular-nums">{pops}</span>
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
    Icon: IconTrackpad,
    variant: 'touch',
    title: 'Your Trackpad is the Wrap',
    desc: 'Apply physical pressure to your Mac trackpad. You literally feel the bubbles pop directly under your fingers.',
  },
  {
    Icon: IconHaptics,
    variant: 'physics',
    title: 'Force Touch Engine',
    desc: 'We reverse-engineered Apple’s Taptic Engine to deliver precise, localized haptic clicks that mimic snapping plastic.',
  },
  {
    Icon: IconPhysics,
    variant: 'custom',
    title: 'Liquid Glass Physics',
    desc: 'Bubbles squish, stretch, and deform naturally before they burst. Built entirely with native AppKit animations.',
  },
  {
    Icon: IconMenubar,
    variant: 'native',
    title: 'Menu Bar Native',
    desc: 'A lightweight utility that lives quietly in your menu bar. Drop it down whenever you need to relieve some stress.',
  },
]

/* ═══════════════════════════════════════
   Navbar
   ═══════════════════════════════════════ */
function Navbar() {
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 30)
    window.addEventListener('scroll', fn, { passive: true })
    return () => window.removeEventListener('scroll', fn)
  }, [])

  return (
    <nav className={`fixed top-0 inset-x-0 z-50 transition-all duration-200 ${
      scrolled ? 'backdrop-blur-xl bg-surface/70 border-b border-glass-border' : ''
    }`}>
      <div className="w-full max-w-3xl mx-auto px-6 h-14 flex items-center justify-between">
        <span className="text-[15px] font-semibold tracking-tight text-text-primary">
          bubblewrap
        </span>
        <a href="/BubbleWrap.zip" download="BubbleWrap.zip"
          className="text-[13px] text-text-secondary hover:text-text-primary transition-colors py-1.5 px-3 rounded-lg hover:bg-white/5">
          Download
        </a>
      </div>
    </nav>
  )
}

/* ═══════════════════════════════════════
   Download Button (reusable)
   ═══════════════════════════════════════ */
function DownloadButton() {
  return (
    <a href="/BubbleWrap.zip" download="BubbleWrap.zip" className="cta inline-flex group">
      <AppleLogo />
      <div className="text-left">
        <span className="block text-[10px] text-text-tertiary uppercase tracking-[1.5px] leading-none mb-0.5">
          Download for
        </span>
        <span className="block text-base font-semibold leading-none">
          macOS
        </span>
      </div>
    </a>
  )
}

/* ═══════════════════════════════════════
   Page — everything centered on a single
   consistent max-w-3xl (672px) axis
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

      <main className="relative z-10 w-full max-w-3xl mx-auto px-6">

        {/* ── Hero ── */}
        <section className="min-h-[100dvh] flex flex-col items-center justify-center text-center">
          <div ref={heroRef} className="reveal">

            <div className="mb-12">
              <HeroBubble />
            </div>

            <h1 className="text-[clamp(2.5rem,6vw,3.75rem)] font-bold tracking-[-0.03em] leading-[1.1] mb-5">
              <span className="bg-gradient-to-b from-white via-white/80 to-white/40 bg-clip-text text-transparent">
                Pop stress away.
              </span>
            </h1>

            <p className="text-base sm:text-lg text-text-secondary leading-relaxed max-w-md mx-auto mb-10">
              Digital bubble wrap with real Force Touch haptics.
              A macOS menu bar app you can feel.
            </p>

            <DownloadButton />
          </div>
        </section>

        <div className="sep" />

        {/* ── Features ── */}
        <section className="py-20 sm:py-24">
          <div ref={featRef} className="reveal">

            <div className="text-center mb-12">
              <p className="text-xs text-accent uppercase tracking-[3px] font-medium mb-3">
                How it works
              </p>
              <h2 className="text-2xl sm:text-3xl font-semibold tracking-tight">
                It pops. You feel it.
                <br />
                <span className="text-text-secondary font-normal">That's the whole point.</span>
              </h2>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 sm:gap-10">
              {features.map(({ Icon, variant, title, desc }) => (
                <div key={title} className="glass feat text-center flex flex-col justify-center items-center h-full">
                  <div className="flex flex-col items-center">
                    <div className={`feat-icon feat-icon--${variant} mb-5`}>
                      <Icon />
                    </div>
                    <h3 className="text-[16px] font-semibold text-text-primary mb-3 leading-tight tracking-tight">
                      {title}
                    </h3>
                    <p className="text-[13px] leading-[1.65] text-text-secondary max-w-[240px]">
                      {desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        <div className="sep" />

        {/* ── Interactive Playground ── */}
        <section className="py-20 sm:py-24">
          <div ref={gridRef} className="reveal max-w-sm mx-auto">
            <BubbleGrid />
          </div>
        </section>

        <div className="sep" />

        {/* ── Final CTA ── */}
        <section id="download" className="py-20 sm:py-28">
          <div ref={ctaRef} className="reveal text-center">
            <h2 className="text-2xl sm:text-3xl font-semibold tracking-tight mb-3">
              Your trackpad, but satisfying.
            </h2>
            <p className="text-sm text-text-secondary mb-8 max-w-xs mx-auto">
              No ads. No bloat. Just bubble wrap that lives in your menu bar.
            </p>
            <DownloadButton />
          </div>
        </section>

        {/* ── Footer ── */}
        <footer className="border-t border-glass-border py-6">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
            <span className="text-xs text-text-tertiary">bubblewrap</span>
            <p className="text-xs text-text-tertiary">
              Built with Swift + AppKit. Requires Force Touch trackpad.
            </p>
          </div>
        </footer>
      </main>
    </>
  )
}
