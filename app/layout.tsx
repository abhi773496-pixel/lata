import './globals.css'; import type {Metadata} from 'next'; import type {ReactNode} from 'react';
export const metadata:Metadata={title:"Silver Beauty Parlour | Women's Beauty Salon in Udaipur",description:"Silver Beauty Parlour in Udaipur offers women's hair care, skin treatments, waxing, nail services, makeup and beauty services. Request your appointment online.",robots:{index:true,follow:true}};
export default function RootLayout({children}:{children:ReactNode}){return <html lang="en"><body>{children}</body></html>}
