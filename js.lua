--[[
    Jumpscare — versi diperbaiki

    MASALAH ASLINYA: gambarnya putih polos.
    Itu BUKAN gambarnya yang putih. Itu BackgroundColor3 ImageLabel yang kelihatan
    karena gambarnya gagal dimuat, sementara BackgroundTransparency tidak pernah
    di-set (default 0 = solid).

    KENAPA GAGAL DIMUAT (dicek live, bukan tebakan):
        MarketplaceService:GetProductInfo(7775787392)
            -> "Huggy Jumpscare" | AssetTypeId = 13 (Decal)

    Properti `Image` hanya menerima aset bertipe Image/Texture. Decal itu cuma
    pembungkus -- di dalamnya ada Image ID lain, dan itu yang sebenarnya dirender.
    Trik lama "decal ID plus/minus 1" juga sudah mati (dites: ...391 dan ...393
    dua-duanya gagal).

    Audionya bunyi karena ID audio memang bertipe Audio yang benar -- itu sebabnya
    gejalanya "suara ada, gambar putih".

    SOLUSINYA: pakai rbxthumb://, yang MENERIMA Decal ID langsung dan tidak butuh
    autentikasi. Dibuktikan berdampingan: rbxthumb tampil, rbxassetid hitam kosong.

    CATATAN RESOLUSI: rbxthumb maksimal 420x420, jadi kalau dibentang fullscreen
    hasilnya agak lembut. Kalau mau tajam, cari Image ID aslinya: buka
    roblox.com/library/7775787392, klik kanan gambarnya -> Copy image address,
    ambil angka setelah "id=", lalu isi ke IMAGE_ID di bawah dan set
    PAKAI_THUMB = false.
]]

--=========================== PENGATURAN ===========================--

local IMAGE_ID    = "7775787392"        -- ID decal ATAU image
local PAKAI_THUMB = true                -- true = rbxthumb (buat Decal ID)
                                        -- false = rbxassetid (kalau IMAGE_ID sudah tipe Image)
local SOUND_ID    = "139162107746216"
local DETIK       = 4                   -- lama tampil
local VOLUME      = 10
local SPEED       = 1
local MULAI_DARI  = 0

--==================================================================--

local Players      = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Content      = game:GetService("ContentProvider")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- Sisa dari eksekusi sebelumnya dibersihkan dulu, kalau tidak setiap kali
-- dijalankan bakal menumpuk satu layar lagi di atasnya.
local lama = PlayerGui:FindFirstChild("__jumpscare")
if lama then lama:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name            = "__jumpscare"
gui.ResetOnSpawn    = false
gui.IgnoreGuiInset  = true              -- tutup sampai ke balik topbar
gui.DisplayOrder    = 2147483647        -- di atas semua GUI lain
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.Parent          = PlayerGui

local label = Instance.new("ImageLabel")
label.Size                  = UDim2.new(1, 0, 1, 0)
label.BorderSizePixel       = 0
-- INI perbaikan yang bikin gejalanya tidak lagi menyamar:
-- kalau gambar gagal dimuat, layarnya bening -- bukan putih polos yang
-- bikin salah sangka "gambarnya memang putih".
label.BackgroundTransparency = 1
label.ScaleType             = Enum.ScaleType.Crop   -- penuhi layar tanpa gepeng
label.Image = PAKAI_THUMB
    and ("rbxthumb://type=Asset&id=%s&w=420&h=420"):format(IMAGE_ID)
    or  ("rbxassetid://" .. IMAGE_ID)
label.Parent = gui

local audio = Instance.new("Sound")
audio.SoundId       = "rbxassetid://" .. SOUND_ID
audio.PlaybackSpeed = SPEED
audio.TimePosition  = MULAI_DARI
audio.Volume        = VOLUME
audio.Parent        = SoundService

-- Dimuat lebih dulu supaya gambar & suara muncul BERSAMAAN. Tanpa ini gambarnya
-- sering telat sepersekian detik karena baru mulai diunduh saat ditampilkan.
pcall(function() Content:PreloadAsync({ label, audio }) end)

-- Laporkan kalau gambarnya tetap gagal, daripada cuma menampilkan layar kosong
-- dan bikin bingung seperti kemarin.
if not label.IsLoaded then
    warn(("[jumpscare] gambar %s GAGAL dimuat. Kalau ini Decal ID, pastikan PAKAI_THUMB = true."):format(IMAGE_ID))
end

audio:Play()
task.wait(DETIK)

gui:Destroy()
audio:Stop()
audio:Destroy()   -- Sound-nya dulu tidak pernah dibuang: tiap kali dijalankan
                  -- meninggalkan satu instance nyangkut di SoundService.
