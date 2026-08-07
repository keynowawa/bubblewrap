import { useState, useCallback, useRef, useEffect } from 'react'

/* ═══════════════════════════════════════
   SVG Icons
   ═══════════════════════════════════════ */

function IconTouch() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 1v4M12 19v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M1 12h4M19 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83" />
      <circle cx="12" cy="12" r="3" fill="currentColor" opacity="0.3" />
    </svg>
  )
}

function IconPhysics() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9" />
      <ellipse cx="12" cy="12" rx="9" ry="4" />
      <line x1="12" y1="3" x2="12" y2="21" />
    </svg>
  )
}

function IconCustom() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" opacity="0.4" strokeDasharray="2 2" />
    </svg>
  )
}

function IconNative() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10" />
      <path d="M16 2.5c2.5 2 4.5 5.5 4.5 9.5" opacity="0.4" />
      <circle cx="18" cy="6" r="3" />
      <path d="M17 6h2M18 5v2" />
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
    Icon: IconTouch,
    variant: 'touch',
    title: 'Force Touch haptics',
    desc: 'Pressure-sensitive popping with real haptic feedback you feel through your trackpad.',
  },
  {
    Icon: IconPhysics,
    variant: 'physics',
    title: 'Real deformation',
    desc: 'Bubbles squish and stretch under pressure before they pop. Popped bubbles show crinkled plastic.',
  },
  {
    Icon: IconCustom,
    variant: 'custom',
    title: 'Configurable sheets',
    desc: 'Three grid sizes matched to 16:10 trackpads. Color tints. Lifetime pop counter.',
  },
  {
    Icon: IconNative,
    variant: 'native',
    title: 'Menu bar native',
    desc: 'Built with AppKit and frosted glass. Lives in your menu bar. No dock icon, no Electron.',
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
        <a href="https://github.com/keynowawa/bubblewrap" target="_blank" rel="noopener noreferrer"
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
    <a href="https://github.com/keynowawa/bubblewrap" target="_blank" rel="noopener noreferrer" className="cta inline-flex">
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

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {features.map(({ Icon, variant, title, desc }) => (
                <div key={title} className="glass feat text-center">
                  <div className="flex flex-col items-center">
                    <div className={`feat-icon feat-icon--${variant} mb-4`}>
                      <Icon />
                    </div>
                    <h3 className="text-[15px] font-medium text-text-primary mb-2 leading-tight">
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
