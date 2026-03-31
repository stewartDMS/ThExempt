/** URL of the deployed Flutter web app (set via NEXT_PUBLIC_APP_URL env var). */
export const APP_URL =
  process.env.NEXT_PUBLIC_APP_URL ?? 'https://th-exempt-wqjc.vercel.app'

export const SIGN_IN_URL = `${APP_URL}/login`
export const SIGN_UP_URL = `${APP_URL}/signup`
