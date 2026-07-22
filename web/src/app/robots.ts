import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/admin/", "/api/", "/auth/", "/dashboard/", "/partners/", "/venue/"],
    },
    sitemap: "https://www.getoutly.app/sitemap.xml",
    host: "https://www.getoutly.app",
  };
}
