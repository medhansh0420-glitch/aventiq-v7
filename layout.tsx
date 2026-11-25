import './globals.css';

export const metadata = {
  title: 'AventIQ — Find your next possibility',
  description: 'A considered space to discover opportunities, learn from mentors and move forward with clarity.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body>{children}</body></html>;
}
