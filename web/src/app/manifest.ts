import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Outly — Toronto Nightlife",
    short_name: "Outly",
    description:
      "See where people are going tonight, choose a Toronto bar, and meet in real life.",
    start_url: "/",
    display: "standalone",
    background_color: "#080b10",
    theme_color: "#080b10",
    icons: [
      {
        src: "/brand/outly-mark.png",
        sizes: "512x512",
        type: "image/png",
      },
    ],
  };
}
