import { Client, Events, GatewayIntentBits, AttachmentBuilder } from "discord.js";
import { exec } from "node:child_process";
import { readFileSync, unlinkSync, existsSync } from "node:fs";
import { join } from "node:path";

interface User {
  name: string;
  photo: boolean;
  intro: string;
  outro: string;
}

const ROOT = join(__dirname, "..");
const TOKEN = readFileSync(join(ROOT, "token.txt"), "utf-8").trim();
const users: User[] = JSON.parse(readFileSync(join(ROOT, "users.json"), "utf-8"));

const PHOTO_PATH = "/tmp/discodog_capture.jpg";
const FSWEBCAM_CMD = `fswebcam -r 1280x720 --no-banner ${PHOTO_PATH}`;

function canTakePhoto(username: string): boolean {
  return users.some((u) => u.name === username && u.photo);
}

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});

client.once(Events.ClientReady, (c) => {
  console.log(`Logged in as ${c.user.tag}`);
});

client.on(Events.MessageCreate, async (message) => {
  if (message.author.bot) return;
  if (message.content !== "!photo") return;

  if (!canTakePhoto(message.author.username)) {
    await message.reply("You don't have permission to take photos.");
    return;
  }

  const status = await message.channel.send("Capturing photo...");

  exec(FSWEBCAM_CMD, async (error, _stdout, stderr) => {
    if (error) {
      console.error("fswebcam error:", stderr);
      await status.edit("Failed to capture photo.");
      return;
    }

    if (!existsSync(PHOTO_PATH)) {
      await status.edit("Photo file not found after capture.");
      return;
    }

    const file = new AttachmentBuilder(readFileSync(PHOTO_PATH), {
      name: "photo.jpg",
    });

    await status.delete().catch(() => {});
    await message.channel.send({ files: [file] }).then((msg) => {
      setTimeout(() => msg.delete().catch(() => {}), 10_000);
    });

    try {
      unlinkSync(PHOTO_PATH);
    } catch {
      // ignore cleanup errors
    }
  });
});

client.login(TOKEN);
