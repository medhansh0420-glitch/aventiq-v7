import DiscoverSection from '../DiscoverSection';
import ConsultationHub from '../ConsultationHub';
import MentorMarketplace from '../MentorMarketplace';
import ScrollEffects from '../ScrollEffects';
import PublicTrustCommunity from '../PublicTrustCommunity';

const steps = [
  ['01','Discover','A focused starting point for scholarships, research, internships and competitions.'],
  ['02','Understand','Clear details help students decide what is relevant before they invest time.'],
  ['03','Connect','Learn from mentors and peers as you move from interest to action.'],
];

export default function Home(){
  return <main className="site-shell">
    <ScrollEffects/>
    <header className="nav container">
      <a href="#top" className="brand" aria-label="AventIQ home"><span className="brandmark">A</span>AventIQ</a>
      <nav className="navlinks" aria-label="Main navigation">
        <a href="#discover">Opportunities</a><a href="#mentors">Mentors</a><a href="#public-world">Community</a><a href="#consultations">Consultations</a>
      </nav>
      <a href="#discover" className="nav-cta">Explore AventIQ <span aria-hidden="true">↗</span></a>
    </header>

    <section id="top" className="hero container">
      <div className="hero-copy reveal">
        <div className="eyebrow"><span className="dot"/> A clearer path to what comes next</div>
        <h1>Make your next move <em>count.</em></h1>
        <p className="hero-lede">Discover meaningful opportunities. Learn from people who have been there. Build momentum with a community that thinks beyond borders.</p>
        <div className="hero-actions"><a href="#discover" className="primary">Explore opportunities <span>↗</span></a><a href="#mentors" className="secondary">Meet the mentor network</a></div>
        <div className="hero-proof"><span className="proof-line"></span><span>One place to discover, connect and grow</span></div>
      </div>
      <div className="hero-art reveal" aria-label="AventIQ platform preview">
        <div className="orbit orbit-one"></div><div className="orbit orbit-two"></div>
        <div className="preview-window">
          <div className="preview-top"><span></span><span></span><span></span><b>AVENTIQ / DISCOVER</b></div>
          <div className="preview-body"><div className="preview-kicker">YOUR NEXT CHAPTER</div><div className="preview-title">Find the right<br/><i>opportunity.</i></div>
            <div className="preview-row"><span className="preview-icon">✳</span><div><b>Scholarship pathways</b><small>Funding · Global study</small></div><span className="preview-arrow">↗</span></div>
            <div className="preview-row"><span className="preview-icon sage">⌁</span><div><b>Mentor conversations</b><small>Guidance · Real experience</small></div><span className="preview-arrow">↗</span></div>
            <div className="preview-row"><span className="preview-icon sand">◎</span><div><b>Community insight</b><small>Ideas · Shared learning</small></div><span className="preview-arrow">↗</span></div>
          </div>
        </div>
        <div className="floating-note"><span className="floating-dot"></span><div><b>Think globally.</b><small>Act on what matters.</small></div></div>
        <div className="art-caption">DISCOVER / CONNECT / GROW</div>
      </div>
      <div className="hero-bottom"><div><strong>01</strong><span>Discover with intention</span></div><div><strong>02</strong><span>Learn from experience</span></div><div><strong>03</strong><span>Move forward confidently</span></div></div>
    </section>

    <section className="intro-band reveal"><div className="container intro-grid"><p className="eyebrow">THE AVENTIQ APPROACH</p><h2>Ambition is everywhere.<br/><em>Access should be, too.</em></h2><p>AventIQ brings opportunity discovery, mentorship and community into one considered experience—designed to help people find direction, wherever they are.</p></div></section>

    <section className="story-section container reveal" id="challenge">
      <div className="story-label"><span>01 / THE CHALLENGE</span><div className="vertical-rule"></div></div>
      <div className="story-content"><h2>Good opportunities are out there. Finding the right ones is the hard part.</h2><div className="story-columns"><p>Information is scattered across websites, social feeds and word of mouth. Students spend valuable time searching, comparing and trying to understand what applies to them.</p><p>And even when an opportunity looks promising, the next questions remain: how do I prepare, who can guide me, and what should I do next?</p></div></div>
    </section>

    <section className="solution-section reveal"><div className="container solution-grid"><div><p className="eyebrow light">02 / A MORE CONNECTED WAY</p><h2>From searching alone<br/>to moving <em>with clarity.</em></h2></div><p>AventIQ connects the dots between discovering an opportunity, learning from people and taking a thoughtful next step. Less noise. More context. A clearer way forward.</p></div><div className="solution-ribbon"><span>DISCOVER</span><b>✳</b><span>CONNECT</span><b>✳</b><span>GROW</span><b>✳</b><span>REPEAT</span></div></section>

    <div className="section-intro container reveal"><div><p className="eyebrow">03 / THE OPPORTUNITY LANDSCAPE</p><h2>Find something worth<br/><em>your next step.</em></h2></div><p>Explore the current collection and use filters to narrow your search. Always confirm eligibility, deadlines and application details with the official provider.</p></div>
    <DiscoverSection/>

    <section className="featured-strip reveal"><div className="container featured-inner"><div><span className="eyebrow light">A BETTER WAY TO EXPLORE</span><h2>Less time navigating tabs.<br/><em>More time making progress.</em></h2></div><a href="#discover">Browse the collection ↗</a></div></section>

    <section className="mentor-intro container reveal"><div><p className="eyebrow">04 / PEOPLE MAKE THE DIFFERENCE</p><h2>Perspective changes<br/><em>what feels possible.</em></h2></div><p>Mentorship can turn a confusing process into a more confident plan. Explore guidance profiles and discover the kinds of conversations that can help you move forward.</p></section>
    <MentorMarketplace/>

    <section id="portfolio" className="portfolio-band reveal"><div className="container portfolio-grid"><div><p className="eyebrow light">05 / BE KNOWN FOR YOUR WORK</p><h2>Your experience can<br/>open a door for <em>someone else.</em></h2></div><p>A public professional portfolio can help people understand your interests, experience and areas of guidance. Public visibility should always be an explicit choice, with private contact details kept protected.</p></div></section>

    <section id="consultations" className="consult-intro container reveal"><div><p className="eyebrow">06 / MAKE THE CONVERSATION COUNT</p><h2>Good guidance starts<br/><em>with a conversation.</em></h2></div><p>Use a dedicated consultation space to discuss a goal, ask questions and learn from another perspective. Share meeting links privately with the intended participant.</p></section>
    <ConsultationHub/>

    <PublicTrustCommunity/>

    <section className="revenue-section reveal"><div className="container revenue-grid"><div><p className="eyebrow light">08 / A SUSTAINABLE NETWORK</p><h2>Built around value.<br/><em>Designed for trust.</em></h2></div><div><p>AventIQ's long-term model can support premium mentor services and platform tools while keeping discovery useful and transparent. Any fees, commissions or paid features should be clearly disclosed before a user commits.</p><span className="revenue-note">No payment processing is enabled in this prototype.</span></div></div></section>

    <section className="vision-section container reveal"><div className="vision-number">09</div><div><p className="eyebrow">THE FUTURE OF AVENTIQ</p><h2>A world where potential<br/>isn't limited by <em>proximity.</em></h2><p>We imagine a global network where opportunity, knowledge and generous guidance can travel across borders—while every person remains in control of what they share.</p></div><div className="vision-mark" aria-hidden="true">A<span>.</span></div></section>

    <section className="final-cta reveal"><div className="container final-inner"><p className="eyebrow light">YOUR NEXT CHAPTER STARTS HERE</p><h2>Make room for<br/><em>what's possible.</em></h2><a href="#discover" className="final-button">Start exploring <span>↗</span></a></div></section>
    <footer><div className="container footer-inner"><a href="#top" className="brand"><span className="brandmark">A</span>AventIQ</a><p>Discover with intention. Connect with care. Grow without borders.</p><div className="footer-links"><a href="#discover">Opportunities</a><a href="#mentors">Mentors</a><a href="#public-world">Community</a></div><small>© {new Date().getFullYear()} AventIQ · Verify opportunity details with official sources.</small></div></footer>
  </main>
}
