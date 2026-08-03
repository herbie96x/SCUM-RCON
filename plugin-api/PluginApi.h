// SPDX-License-Identifier: LicenseRef-SCUM-RCON-EULA
// Copyright (c) 2026 herbie (SKRYPT). All rights reserved.
//
// This file is part of SCUM-RCON. Proprietary software - use is governed by
// the End User License Agreement in the LICENSE file. This is NOT
// open-source software.

#pragma once

#include <stdint.h>

// SCUM-RCON plugin API — the stable C ABI other UE4SS mods use to plug into
// this mod's command router. A separately-built plugin DLL cannot share C++
// types (std::string / std::function / Result) across the module boundary, so
// everything here is plain C: fixed-layout structs and function pointers.
//
// A plugin obtains the API by resolving the exported entry point from this
// mod's DLL and calling it with the ABI version it was built against:
//
//   const ScumRcon_Api* api = ScumRcon_GetApi(SCUMRCON_API_VERSION);
//   if (api) api->register_command("MyCommand", &my_handler, 1, my_ctx, "what it does");
//
// (Discovery: our DLL is loaded as "main.dll" in its own mods folder — a plugin
// enumerates loaded modules and takes the first that exports ScumRcon_GetApi.)
//
// ABI stability rule: NEVER reorder or change existing struct fields once
// shipped. Add new fields ONLY at the end and bump SCUMRCON_API_VERSION.
//
// Because the struct only ever grows at the end, a plugin built against an
// OLDER version stays valid: it reads the prefix it knows and ignores the rest.
// ScumRcon_GetApi therefore accepts any version up to and including this
// build's — it does NOT require an exact match. Requesting a NEWER version than
// the mod provides returns NULL (the plugin would read past the end of a table
// that does not have those slots yet).

#ifdef __cplusplus
extern "C"
{
#endif

#define SCUMRCON_API_VERSION 1u

    // Where the command entered the mod.
    enum ScumRcon_Source
    {
        SCUMRCON_SOURCE_RCON   = 0,
        SCUMRCON_SOURCE_INGAME = 1
    };

    // Who is running the command.
    typedef struct ScumRcon_Caller
    {
        int         source;    // one of ScumRcon_Source
        const char* steam_id;  // in-game caller SteamID (UTF-8), or NULL for RCON
        int         is_admin;  // 0 / 1
    } ScumRcon_Caller;

    // Output sink handed to a handler (and to dispatch): the plugin pushes reply
    // lines via emit and an error via set_error. `ctx` is opaque — pass it back
    // unchanged. Pointers are valid only for the duration of the call.
    typedef struct ScumRcon_Reply
    {
        void (*emit)(void* ctx, const char* line);
        void (*set_error)(void* ctx, const char* msg);
        void* ctx;
    } ScumRcon_Reply;

    // A plugin command handler. argv[0] is the verb; argc >= 1. Return 0 on
    // success, non-zero on failure. Do NOT retain argv or any string past the
    // call. `user` is the pointer passed at register_command time.
    typedef int (*ScumRcon_HandlerFn)(int argc, const char* const* argv,
                                      const ScumRcon_Caller* caller,
                                      ScumRcon_Reply* reply, void* user);

    // A one-shot task for enqueue_game_thread. `user` is passed straight back.
    typedef void (*ScumRcon_TaskFn)(void* user);

    // The API surface. Do not construct — obtain via ScumRcon_GetApi.
    typedef struct ScumRcon_Api
    {
        uint32_t abi_version;

        // Registers a command. Case-insensitive; first registration wins and can
        // never shadow a built-in/self-built command. Returns 1 on success, 0 if
        // the name is taken or invalid.
        //   admin_only  1 = in-game callers must be server admins (RCON is always
        //               trusted). ENFORCED — a non-admin in-game caller is
        //               rejected before the handler runs.
        //   description optional one-liner listed by the built-in '/plugins'
        //               command. May be NULL.
        // The name "plugins" is reserved and cannot be registered.
        int (*register_command)(const char* name, ScumRcon_HandlerFn fn,
                                int admin_only, void* user,
                                const char* description);

        // Runs a full command line through the mod's dispatcher as a trusted
        // (RCON/admin) caller; reply lines go to the sink. Returns 0 on success.
        // GAME-THREAD ONLY — same contract as the mod's own dispatch(). From
        // your own thread, wrap it in enqueue_game_thread.
        int (*dispatch)(const char* command_line, ScumRcon_Reply* reply);

        // Writes a line to the mod log.
        void (*log)(const char* line);

        // Runs `fn(user)` on the game thread, once, at the next engine tick.
        // This is how a plugin's own thread (timer, socket worker, ...) reaches
        // anything engine-side safely — including api->dispatch. Returns 1 when
        // queued, 0 when the mod is shutting down (the task will NOT run).
        // Safe to call from any thread. `user` must stay alive until fn runs.
        int (*enqueue_game_thread)(ScumRcon_TaskFn fn, void* user);
    } ScumRcon_Api;

    // The single exported entry point. Pass the version you built against.
    // Returns NULL only if that version is NEWER than this build provides.
    __declspec(dllexport) const ScumRcon_Api* ScumRcon_GetApi(uint32_t abi_version);

#ifdef __cplusplus
} // extern "C"
#endif
