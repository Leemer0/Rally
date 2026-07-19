import { ImageResponse } from "next/og";
import { readFile } from "node:fs/promises";
import { join } from "node:path";

export const alt = "Outly — Say you met at a bar, not a dating app.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const runtime = "nodejs";

async function imageData(path: string) {
  const image = await readFile(join(process.cwd(), "public", path));
  return `data:image/png;base64,${image.toString("base64")}`;
}

export default async function OpenGraphImage() {
  const [logoData, nightlifeData, appMapData] = await Promise.all([
    imageData("brand/winged-o.png"),
    imageData("brand/outly-night-arrival.png"),
    imageData("product/explore-v2.png"),
  ]);

  return new ImageResponse(
    (
      <div
        style={{
          position: "relative",
          display: "flex",
          width: "100%",
          height: "100%",
          overflow: "hidden",
          background: "#080b10",
          color: "#f5f4ef",
          fontFamily: "sans-serif",
        }}
      >
        <img
          src={nightlifeData}
          alt=""
          width="700"
          height="630"
          style={{
            position: "absolute",
            right: 0,
            top: 0,
            width: 700,
            height: 630,
            objectFit: "cover",
            objectPosition: "66% center",
          }}
        />

        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            backgroundImage:
              "linear-gradient(90deg, #080b10 0%, #080b10 41%, rgba(8,11,16,.91) 52%, rgba(8,11,16,.28) 76%, rgba(8,11,16,.08) 100%)",
          }}
        />

        <div
          style={{
            position: "absolute",
            inset: 0,
            display: "flex",
            backgroundImage: "linear-gradient(0deg, rgba(8,11,16,.46), transparent 34%)",
          }}
        />

        <div
          style={{
            position: "relative",
            display: "flex",
            flexDirection: "column",
            width: 760,
            height: "100%",
            padding: "54px 0 52px 64px",
          }}
        >
          <img
            src={logoData}
            alt="Outly"
            width="112"
            height="56"
            style={{ width: 112, height: 56, objectFit: "contain" }}
          />

          <div
            style={{
              display: "flex",
              marginTop: 54,
              color: "#b9ff37",
              fontSize: 17,
              fontWeight: 600,
              letterSpacing: ".2em",
              textTransform: "uppercase",
            }}
          >
            Toronto · meet tonight
          </div>

          <div
            style={{
              display: "flex",
              flexDirection: "column",
              marginTop: 20,
              fontSize: 65,
              fontWeight: 650,
              lineHeight: 0.94,
              letterSpacing: "-.055em",
            }}
          >
            <span>Say you met at a bar,</span>
            <span style={{ color: "#b9ff37", marginTop: 12 }}>not a dating app.</span>
          </div>

          <div
            style={{
              display: "flex",
              marginTop: 32,
              maxWidth: 530,
              color: "rgba(245,244,239,.67)",
              fontSize: 23,
              lineHeight: 1.35,
            }}
          >
            See where Toronto is going. Pick a bar. Meet in real life.
          </div>
        </div>

        <div
          style={{
            position: "absolute",
            right: 82,
            bottom: -92,
            display: "flex",
            width: 238,
            height: 518,
            overflow: "hidden",
            padding: 6,
            border: "1px solid rgba(255,255,255,.34)",
            borderRadius: 42,
            background: "#030508",
            boxShadow: "0 28px 72px rgba(0,0,0,.58)",
          }}
        >
          <img
            src={appMapData}
            alt="Outly map"
            width="226"
            height="492"
            style={{ width: 226, height: 492, objectFit: "cover", borderRadius: 36 }}
          />
        </div>

        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            bottom: 0,
            display: "flex",
            height: 8,
            background: "#b9ff37",
          }}
        />
      </div>
    ),
    size,
  );
}
