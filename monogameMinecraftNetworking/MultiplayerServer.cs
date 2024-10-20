﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Enumeration;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using MessagePack;
using Microsoft.Xna.Framework;
using monogameMinecraftNetworking.Asset;
using monogameMinecraftNetworking.Data;
using monogameMinecraftNetworking.Protocol;
using monogameMinecraftNetworking.Updateables;
using monogameMinecraftNetworking.Utility;
using monogameMinecraftNetworking.World;
using monogameMinecraftShared.Core;
using EntityData = monogameMinecraftNetworking.Data.EntityData;
namespace monogameMinecraftNetworking
{
    public class MultiplayerServer:IMultiplayerServer
    {
      //  public List<MessageParser> messageParser { get; set; }
      public object remoteClientsLock
      {
          get { return _remoteClientsLock; }
      }

      private object _remoteClientsLock=new object();

        public object todoListLock
        {
            get { return _todoListLock; }
        }

        private object _todoListLock = new object();
        public List<RemoteClient> remoteClients { get; set; }
        public List<ServerTodoList> serverTodoLists { get; set; }
        public  UserAccessControllingManager userAccessControllingManager { get; set; }
        public bool isGoingToQuit { get; set; } = false;
        public List<IUpdatingManager> updatingManagers { get; set; }
        public List<UserData> allUserDatas
        {
            get
            {
                List<UserData> retValue= new List<UserData>();
                lock (remoteClientsLock)
                {
                    foreach (var item in remoteClients)
                    {
                        if (item.isUserDataLoaded == true)
                        {
                            retValue.Add(item.curUserData);
                        }
                    }
                }
             
                return retValue;

            }
        }

        public Thread socketWaitThread;
        public void SocketWait(Socket socket)
        {
            while (true)
            {
                try
                {
                    socket.Listen();
                    Socket s = socket.Accept();

                    RemoteClient client = new RemoteClient(s, null, this);
                    client.isUserDataLoaded = false;
                    lock (remoteClientsLock)
                    {
                        remoteClients.Add(client);
                    }


                    //   allClientSockets.Add(s);
                    // Thread t = new Thread(new ParameterizedThreadStart(RecieveClient));
                    //  t.Start(s);
                    Console.WriteLine("connected");
                    Console.WriteLine(socket.LocalEndPoint.ToString());
                }
                catch (Exception e)
                {
                    Console.WriteLine("quit waiter thread: "+e);
                    return;
                }
              
            }


        }

        public Socket serverSocket;
        public IPEndPoint ipEndPoint{ get; set; }
        public void Initialize(string ipAddress1, int port)
        {
            userAccessControllingManager = new UserAccessControllingManager(Directory.GetCurrentDirectory() + "/bannedusers.json");
            ServerSideBlockResourcesManager.LoadBlockInfo(Directory.GetCurrentDirectory()+"/customblockinfodata");
            isGoingToQuit= false;
            foreach (var world in ServerSideVoxelWorld.voxelWorlds)
            {
                world.InitWorld(this);
            }

            ServerSideVoxelWorld.serverInstance = this;
            updatingManagers = new List<IUpdatingManager> { new UserUpdatingManager(this),new EntityUpdatingManager(this),new WorldTimeUpdatingManager(this)};
            remoteClients =new List<RemoteClient>();
            serverTodoLists = new List<ServerTodoList>
            {
                new ServerTodoList(), new ServerTodoList(), new ServerTodoList(), new ServerTodoList() 
               
            };
            ipEndPoint = new IPEndPoint(IPAddress.Parse(ipAddress1), port);
                
            serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            serverSocket.Bind(ipEndPoint);
         
        }

        public Thread executeTodoListThread;
        public void ExecuteToDoList(int listIndex)
        {
            while (true)
            {
                if (isGoingToQuit == true)
                {
                    Console.WriteLine("quit execute todo list thread:" + Thread.CurrentThread.ManagedThreadId);
                    return;
                }


                    Thread.Sleep(1);
                lock (serverTodoLists[listIndex].queueLock)
                {
                    if (serverTodoLists[listIndex].value.Count > 0)
                    {
                        (RemoteClient sourceClient, MessageProtocol message) item;
                        serverTodoLists[listIndex].value.TryDequeue(out item);
                        try
                        {
                            if (item.message == null)
                            {
                                Console.WriteLine("null message received");
                                continue;
                            }

                            switch ((MessageCommandType)item.message.command)
                            {
                                case MessageCommandType.ChunkDataRequest:
                                    ChunkDataRequestData data =
                                        MessagePackSerializer.Deserialize<ChunkDataRequestData>(
                                            item.message.messageData);

                                    if (ServerSideVoxelWorld.voxelWorlds[data.worldID] != null)
                                    {
                                        lock (ServerSideVoxelWorld.voxelWorlds[data.worldID].chunkBuildingQueueLock)
                                        {
                                            ServerSideVoxelWorld.voxelWorlds[data.worldID].chunkBuildingQueue
                                                .Enqueue((item.sourceClient, data.chunkPos));
                                        }
                                    }

                                    break;

                                case MessageCommandType.UserLogin:
                                    Console.WriteLine("login");
                                    NetworkingUtility.UserLogin(item.sourceClient, item.message.messageData, this);

                                    if (item.sourceClient.isUserDataLoaded == true)
                                    {
                                        string broadcastMessage1 =
                                            item.sourceClient.curUserData.userName + " Logged in.";
                                        NetworkingUtility.CastToAllClients(this,
                                            new MessageProtocol((byte)MessageCommandType.ChatMessageBroadcast,
                                                MessagePackSerializer.Serialize(broadcastMessage1)));
                                    }


                                    break;

                                case MessageCommandType.UserLogout:
                                    NetworkingUtility.UserLogout(item.sourceClient, this);
                                    break;


                                case MessageCommandType.UserDataUpdate:
                                    UserData userData =
                                        MessagePackSerializer.Deserialize<UserData>(item.message.messageData);
                                    lock (remoteClientsLock)
                                    {
                                        int idx = remoteClients.FindIndex((client =>
                                        {
                                            if (client.isUserDataLoaded == false)
                                            {
                                                return false;
                                            }

                                            return client.curUserData.userName == userData.userName;
                                        }));
                                        //   Console.WriteLine(userData.userName);
                                        if (idx != -1)
                                        {
                                            remoteClients[idx].curUserData = userData;
                                        }
                                        else
                                        {
                                            Console.WriteLine("unknown user data");
                                            Console.WriteLine(userData.userName);
                                        }
                                    }

                                    break;
                                case MessageCommandType.UserDataRequest:
                                    NetworkingUtility.CastToAllClients(this, item.message, true);
                                    break;

                                case MessageCommandType.UserDataBroadcast:
                                    NetworkingUtility.CastToAllClients(this,
                                        new MessageProtocol((byte)MessageCommandType.UserDataBroadcast,
                                            MessagePackSerializer.Serialize(this.allUserDatas)), true);
                                    break;

                                case MessageCommandType.WorldGenParamsRequest:
                                    int worldID = MessagePackSerializer.Deserialize<int>(item.message.messageData);
                                    NetworkingUtility.SendToClient(item.sourceClient,
                                        new MessageProtocol((byte)MessageCommandType.WorldGenParamsData,
                                            MessagePackSerializer.Serialize(ServerSideVoxelWorld.voxelWorlds[worldID]
                                                .genParamsData)));
                                    break;
                                case MessageCommandType.ChunkUpdateData:
                                    ChunkUpdateData data2 =
                                        MessagePackSerializer
                                            .Deserialize<ChunkUpdateData>(item.message.messageData);
                                    if (ServerSideVoxelWorld.voxelWorlds[data2.worldID] != null)
                                    {
                                        IChunkUpdateOperation? operation1 = IChunkUpdateOperation.ParseFromData(data2,
                                            ServerSideVoxelWorld.voxelWorlds[data2.worldID].worldUpdater);
                                        if (operation1 != null)
                                        {
                                            ServerSideVoxelWorld.voxelWorlds[data2.worldID].worldUpdater
                                                .queuedChunkUpdatePoints.Enqueue(operation1);
                                        }
                                    }


                                    break;

                                case MessageCommandType.EntityDataBroadcast:

                                    NetworkingUtility.CastToAllClients(this,
                                        new MessageProtocol((byte)MessageCommandType.EntityDataBroadcast,
                                            item.message.messageData));
                                    break;

                                case MessageCommandType.HurtEntityRequest:
                                    HurtEntityRequestData data3 =
                                        MessagePackSerializer.Deserialize<HurtEntityRequestData>(item.message
                                            .messageData);
                                    ServerSideEntityBeh entity;
                                    bool isEntityHurt = ServerSideEntityManager.HurtEntity(data3.entityID,
                                        data3.hurtValue,
                                        new Vector3(data3.sourcePosX, data3.sourcePosY, data3.sourcePosZ), out entity);
                                    if (isEntityHurt)
                                    {
                                        if (entity is ServerSideZombieEntityBeh)
                                        {
                                            NetworkingUtility.CastToAllClients(this,
                                                new MessageProtocol((byte)MessageCommandType.EntitySoundBroadcast,
                                                    MessagePackSerializer.Serialize(new EntitySoundBroadcastData(
                                                        entity.position.X, entity.position.Y, entity.position.Z, "0hurt"
                                                    ))));
                                        }

                                        if (entity is ServerSidePigEntityBeh)
                                        {
                                            NetworkingUtility.CastToAllClients(this,
                                                new MessageProtocol((byte)MessageCommandType.EntitySoundBroadcast,
                                                    MessagePackSerializer.Serialize(new EntitySoundBroadcastData(
                                                        entity.position.X, entity.position.Y, entity.position.Z, "1hurt"
                                                    ))));
                                        }
                                    }

                                    break;
                                case MessageCommandType.EntitySoundBroadcast:
                                    NetworkingUtility.CastToAllClients(this,
                                        new MessageProtocol((byte)MessageCommandType.EntitySoundBroadcast,
                                            item.message.messageData));
                                    break;
                                case MessageCommandType.ChatMessage:
                                    if (item.sourceClient.isUserDataLoaded == false)
                                    {
                                        break;
                                    }

                                    string data6 = MessagePackSerializer.Deserialize<string>(item.message.messageData);

                                    string broadcastMessage =
                                        "<" + item.sourceClient.curUserData.userName + "> " + data6;
                                    Console.WriteLine("User chat message: "+broadcastMessage);
                                    NetworkingUtility.CastToAllClients(this,
                                        new MessageProtocol((byte)MessageCommandType.ChatMessageBroadcast,
                                            MessagePackSerializer.Serialize(broadcastMessage)));
                                    break;
                                case MessageCommandType.WorldTimeDataBroadcast:
                                    NetworkingUtility.CastToAllClients(this,
                                       item.message);
                                    break;
                            }
                        }
                        catch (Exception ex)
                        {
                            Console.WriteLine("execute todo list thread exception:" + ex);
                            continue;
                        }
                    }
                }
            }
        }

        public Thread validateClientsThread;
        public void ValidateClientsThread()
        {
            while (true)
            {
                if (isGoingToQuit == true)
                {
                    Console.WriteLine("quit validate clients thread:" + Thread.CurrentThread.ManagedThreadId);
                    return;
                }
                Thread.Sleep(50);
                NetworkingUtility.RemoveDisconnectedClients(this);
                NetworkingUtility.RemoveBannedClients(this);
            }
        }

        public void KickUser(RemoteClient user)
        {
            if (!remoteClients.Contains(user))
            {
                return;
            }
            if (user.messageParser.isMessageParsingThreadRunning==true)
            {
                user.Close();
            }

            remoteClients.Remove(user);
        }
        public void Start()
        {
            socketWaitThread = new Thread(() => { SocketWait(serverSocket); });
            socketWaitThread.Start();

            validateClientsThread = new Thread(ValidateClientsThread);
            validateClientsThread.Start();
            for (int i = 0; i < serverTodoLists.Count; i++)
            {
                Console.WriteLine("thread:"+i);
                var i1 = i;
                Thread t = new Thread(() => { ExecuteToDoList(i1); });
                t.Start();
            }
      //      executeTodoListThread = new Thread(() => { ExecuteToDoList(); });
     //       executeTodoListThread.Start();
            foreach (var item in updatingManagers)
            {
                item.Start();
            }
        }

        public void ShutDown()
        {
            isGoingToQuit = true;
            validateClientsThread.Join();
            foreach (var client in remoteClients)
            {
              client.Close(); 
            }
            foreach (var item in updatingManagers)
            {
                item.Stop();
            }

            foreach (var world in ServerSideVoxelWorld.voxelWorlds)
            {
                world.ShutDown();    
            }
            userAccessControllingManager.SaveBannedUsersList(Directory.GetCurrentDirectory() + "/bannedusers.json");
            serverSocket.Close();
            Console.WriteLine("server shutdown");
        }
    }
}
