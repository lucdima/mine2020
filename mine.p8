pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--- game_state=0 is intro
--- game_state=1 game
--- game_state=2 is gameover loose
--- game_state=3 is gameover win

function _init()
    game_state=0
    start=0
    make_intro()
    make_board()
    offset_x = (128-board.size*9)/2
    offset_y = offset_x + 7
    make_cursor(0,0)
    make_timer()
    make_hud(timer)
end

function _update()
    if game_state==0 then
        intro:update()
    elseif game_state==1 then
        cursor:action()
        timer:update()
    elseif game_state==2 or game_state==3 then
        if any_key() then
            _init()
            game_state=0
        end
    end
end

function _draw()
    if game_state==0 then
        intro:draw()
    elseif game_state==1 then
        board:draw()
        cursor:draw()
        hud:draw()
    elseif game_state==2 or game_state==3 then
        hud:draw()
        cursor:draw()
    end
end

function make_intro()
    cls(13)
    intro={
        f=0,
        draw=function(self)
            spr(2,10,10)
            spr(2,20,10)
            spr(3,20,10)
            spr(5,30,10)
            print(".mine 2020", 40,12,7)
            local color=1
            if self.f<20 then color = 7 end
            print("press any key to start", 20,60,color)
            spr(2,110,100)
            spr(2,100,110)
            spr(2,110,110)
            print("(c) 2020 lucas dima", 10,112,6)
            self.f+=1
            if self.f == 40 then self.f=0 end
        end,
        update=function(self)
            if any_key() then
                cls(13)
                game_state=1
            end
        end
    }
end

function make_cursor(x,y)
    cursor = {
        x=x,
        y=y,
        draw=function(self)
            spr(1,self.x * 9 + offset_x, self.y * 9 + offset_y)
            -- rectfill(0,0,50,10,1)
            -- print(self.x .. "," .. self.y,2,2,5)
        end,
        action=function(self)
            if (btnp(0) and self.x>0) self.x-=1
            if (btnp(1) and self.x<board.size-1) self.x+=1
            if (btnp(2) and self.y>0) self.y-=1
            if (btnp(3) and self.y<board.size-1) self.y+=1
            local has_bomb=board:has_bomb(self.x,self.y)
            local total=board:cound_surrounding(self.x, self.y)
            if (btnp(4)) then
                self.handle_open_button(self)
            end
            if (btnp(5)) then
                self.handle_flag_button(self)
            end

            -- print(total .. has_bomb_message,5,117,5)
        end,
        handle_flag_button=function(self)
            local tile = board:get_tile(self.x,self.y)
            if not tile:is_closed() then return end
            if tile:get_flag() then
                board:decrement_marked_bombs()
                tile:set_flag(false)
            else
                board:increment_marked_bombs()
                tile:set_flag(true)
            end
        end,
        handle_open_button=function(self)
            if start==0 then
                board:assign_bombs(self.x,self.y)
                board:assign_nearby()
                start=1
            end
            local tile = board:get_tile(self.x,self.y)
            if tile:get_flag() then return end
            tile.closed=false
            if board:has_bomb(self.x,self.y) then
                board:uncover_all()
                game_state=2
                board:draw()
                cursor:draw()
                hud:draw()
                wait(30)
                return
            end
            uncover_recursive(tile,board)
            board:count_uncovered()
            if board:is_all_uncovered() then
                game_state=3
                board:draw()
                cursor:draw()
                hud:draw()
                wait(60)
                return
            end
        end,
    }
end

function make_board()
    board={
        size=10,
        total_bombs=10,
        marked_bombs=0,
        uncovered_tiles=0,
        tiles={},
        add_tile=function(self,tile)
            add(self.tiles,tile)
        end,
        draw=function(self)
            for tile in all(self.tiles) do
                tile:draw()
            end
        end,
        set_bomb=function(self,index)
            self.tiles[index]:set_bomb()
        end,
        has_bomb=function(self,x,y)
            tile=self:get_tile(x,y)
            return tile:has_bomb()
        end,
        assign_bombs=function(self,exclude_x,exclude_y)
            -- create array of amount of tiles
            exclude=self:get_index(exclude_x,exclude_y)
            local a={}
            for i=1,count(self.tiles) do
                if i != exclude then
                    add(a,i)
                end
            end

            -- shuffle the array
            for i=1,1000 do
                rand_pos1 = flr(rnd(count(a)-1)) + 1
                rand_pos2 = flr(rnd(count(a)-1)) + 1
                aux=a[rand_pos1]
                a[rand_pos1]=a[rand_pos2]
                a[rand_pos2]=aux
            end

            -- pick the first 30 (bomb amount elements)
            for i=1,self.total_bombs do
                self:set_bomb(a[i])
            end
        end,
        get_tile=function(self,x,y)
            local index = y*self.size+x+1
            return self.tiles[index]
        end,
        cound_surrounding=function(self,x,y)
            local total=0
            -- top left
            if x>0 and y>0 and self:get_tile(x-1,y-1):has_bomb() then
                total+=1
            end
            -- top
            if y>0 and self:get_tile(x,y-1):has_bomb() then
                 total+=1
            end
            -- top right
            if x<self.size-1 and y>0 and self:get_tile(x+1,y-1):has_bomb() then
                total+=1
            end
            -- right
            if x<self.size-1 and self:get_tile(x+1,y):has_bomb() then
                total+=1
            end
            -- bottom right
            if x<self.size-1 and y<self.size-1 and self:get_tile(x+1,y+1):has_bomb() then
                total+=1
            end
            -- bottom
            if y<self.size-1 and self:get_tile(x,y+1):has_bomb() then
                total+=1
            end
            -- bottom left
            if x>0 and y<self.size-1 and self:get_tile(x-1,y+1):has_bomb() then
                total+=1
            end
            -- left
            if x>0 and self:get_tile(x-1,y):has_bomb() then
                total+=1
            end

            return total
        end,
        get_index=function(self,x,y)
            return (y*self.size+x+1)
        end,
        assign_nearby=function(self)
            for y = 0,self.size-1 do
                for x = 0,self.size-1 do
                    local bombs_near = self:cound_surrounding(x,y)
                    self:get_tile(x,y):set_bombs_near(bombs_near)
                end
            end
        end,
        uncover_all=function(self)
            for tile in all(self.tiles) do
                if tile:has_bomb() then
                    tile:set_closed(false)
                end
            end
        end,
        increment_marked_bombs=function(self)
            self.marked_bombs+=1
        end,
        decrement_marked_bombs=function(self)
            self.marked_bombs-=1
        end,
        count_uncovered=function(self)
            local uncovered=0
            for tile in all(self.tiles) do
                if not tile:is_closed() then
                    uncovered+=1
                end
            end
            self.uncovered_tiles=uncovered
            return uncovered
        end,
        is_all_uncovered=function(self)
            return self.uncovered_tiles + self.total_bombs == self.size * self.size
        end,
    }
    for i = 0,board.size-1 do
        for j = 0,board.size-1 do
            board:add_tile(make_tile(j,i))
        end
    end
end

function make_tile(x,y)
    local tile = {
        x=x,
        y=y,
        bomb = false,
        closed=true,
        bombs_near=0,
        flag=false,
        draw = function(self)
            if self.closed then
                spr(2,self.x * 9 + offset_x,self.y * 9 + offset_y)
                if self.flag then
                    spr(3,self.x * 9 + offset_x,self.y * 9 + offset_y)
                end
                return
            end
            if self.bomb then
                spr(5,self.x * 9 + offset_x,self.y * 9 + offset_y)
                return
            end
            spr(4,self.x * 9 + offset_x,self.y * 9 + offset_y)
            if self.bombs_near>0 then
                -- Add diferent colors to numbers
                local color = self:get_number_color(self.bombs_near)
                print(self.bombs_near,self.x * 9 + offset_x + 3,self.y * 9 + offset_y + 2,color)
            end
        end,
        get_number_color=function(self, number)
            if number==1 then return 1 end
            if number==2 then return 3 end
            if number==3 then return 8 end
            if number==4 then return 5 end
            if number==5 then return 2 end
            if number==6 then return 12 end
            if number==7 then return 1 end
            if number==8 then return 14 end
        end,
        set_bombs_near=function(self, b)
            self.bombs_near = b
        end,
        set_bomb = function(self)
            self.bomb = true
        end,
        has_bomb = function(self)
            return self.bomb
        end,
        is_closed = function(self)
            return self.closed
        end,
        set_closed=function(self,c)
            self.closed=c
        end,
        set_flag=function(self,f)
            self.flag=f
        end,
        get_flag=function(self)
            return self.flag
        end,
        get_bombs_near=function(self)
            return self.bombs_near
        end
    }
    return tile
end

function make_timer()
    timer={
        seconds=0,
        frames=0,
        update=function(self)
            self.frames+=1
            if self.frames%30==0 then
                self.seconds+=1
                if self.seconds==6000 then
                    self.seconds=0
                end
            end
            if self.frames==30 then
                self.frames=0
            end
        end,
        draw=function(self)
            local min=flr(self.seconds/60)
            local sec=self.seconds%60
            rectfill(100,2,126,10,1)
            print(pad(""..min,2) .. ":" .. pad(""..sec,2),106,2,7)
        end
    }
end

function make_hud(timer)
    hud={
        timer=timer,
        draw=function(self)
            rectfill(0,0,128,10,1)
            print(board.marked_bombs,2,2,7)
            -- rectfill(0,12,128,22,1)
            -- print(board.uncovered_tiles,2,12,5)
            display=""
            if game_state==2 then display="game over" end
            if game_state==3 then display="you win!" end
            -- if #self.display>0 then
            print(display,(64-#display*2),16,7)
            -- end
            print("mine 2020",(64-9*2),2,7)
            timer:draw()
        end,
    }
end

function debug(m)
    print(m,5,117,5)
end

function any_key()
    return btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5)
end

function uncover_recursive(tile,board)
    tile.closed=false
    if tile:get_bombs_near() > 0 then
        return
    end

    -- check top left
    if tile.x>0 and tile.y>0 then
        top_left_tile=board:get_tile(tile.x-1,tile.y-1)
        if top_left_tile:is_closed() then
            uncover_recursive(top_left_tile,board)
        end
    end

    -- check top
    if tile.y>0 then
        top_tile=board:get_tile(tile.x,tile.y-1)
        if top_tile:is_closed() then
            uncover_recursive(top_tile,board)
        end
    end

    -- check top right
    if tile.x<board.size-1 and tile.y>0 then
        top_right_tile=board:get_tile(tile.x+1,tile.y-1)
        if top_right_tile:is_closed() then
            uncover_recursive(top_right_tile,board)
        end
    end

    -- check right
    if tile.x<board.size-1 then
        right_tile=board:get_tile(tile.x+1,tile.y)
        if right_tile:is_closed() then
            uncover_recursive(right_tile,board)
        end
    end

    -- check bottom right
    if tile.x<board.size-1 and tile.y<board.size-1 then
        bottom_right_tile=board:get_tile(tile.x+1,tile.y+1)
        if bottom_right_tile:is_closed() then
            uncover_recursive(bottom_right_tile,board)
        end
    end

    -- check bottom
    if tile.y<board.size-1 then
        bottom_tile=board:get_tile(tile.x,tile.y+1)
        if bottom_tile:is_closed() then
            uncover_recursive(bottom_tile,board)
        end
    end

    -- check bottom left
    if tile.x>0 and tile.y<board.size-1 then
        bottom_left_tile=board:get_tile(tile.x-1,tile.y+1)
        if bottom_left_tile:is_closed() then
            uncover_recursive(bottom_left_tile,board)
        end
    end
end

function pad(string,length)
  if (#string==length) return string
  local leading_zeros=""
  for i=1,length-#string do
      leading_zeros = leading_zeros.."0"
  end
  return leading_zeros..string
end

function wait(a) for i = 1,a do flip() end end
__gfx__
00000000880000887777777700000000111111171111111700000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008000000876666661000000001666666716666a6700000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007666666100888100166666671666866700000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000000000076666661008a8100166666671661166700000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000007666666100888100166666671617116700000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000007666666100000100166666671611116700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000087666666100000100166666671661166700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000880000887111111100000000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd77777777dd77777777dd11111117dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666661dd16666a67dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76888161dd16668667dddddd777d777d77dd777ddddd777d777d777d777ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd768a8161dd16611667dddddd777dd7dd7d7d7ddddddddd7d7d7ddd7d7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76888161dd16171167dddddd7d7dd7dd7d7d77dddddd777d7d7d777d7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666161dd16111167dddddd7d7dd7dd7d7d7ddddddd7ddd7d7d7ddd7d7ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd76666661dd76666161dd16611667ddd7dd7d7d777d7d7d777ddddd777d777d777d777ddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddd71111111dd71111111dd77777777dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddd111d111d111dd11dd11ddddd111d11dd1d1ddddd1d1d111d1d1ddddd111dd11dddddd11d111d111d111d111ddddddddddddddddddddd
dddddddddddddddddddd1d1d1d1d1ddd1ddd1ddddddd1d1d1d1d1d1ddddd1d1d1ddd1d1dddddd1dd1d1ddddd1dddd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddd111d11dd11dd111d111ddddd111d1d1d111ddddd11dd11dd111dddddd1dd1d1ddddd111dd1dd111d11ddd1dddddddddddddddddddddd
dddddddddddddddddddd1ddd1d1d1ddddd1ddd1ddddd1d1d1d1ddd1ddddd1d1d1ddddd1dddddd1dd1d1ddddddd1dd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddd1ddd1d1d111d11dd11dddddd1d1d1d1d111ddddd1d1d111d111dddddd1dd11dddddd11ddd1dd1d1d1d1dd1dddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd71111111dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd77777777dd77777777dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd76666661dd76666661dddddddddd
ddddddddddd6ddd66dd6dddddd666d666d666d666ddddd6ddd6d6dd66d666dd66ddddd66dd666d666d666ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddddd6d6d6ddd6d6d6ddddd6ddd6d6d6ddd6d6d6ddddddd6d6dd6dd666d6d6ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddd666d6d6d666d6d6ddddd6ddd6d6d6ddd666d666ddddd6d6dd6dd6d6d666ddddddddddddddd76666661dd76666661dddddddddd
dddddddddd6ddd6ddddd6ddddd6ddd6d6d6ddd6d6ddddd6ddd6d6d6ddd6d6ddd6ddddd6d6dd6dd6d6d6d6ddddddddddddddd76666661dd76666661dddddddddd
ddddddddddd6ddd66dd6dddddd666d666d666d666ddddd666dd66dd66d6d6d66dddddd666d666d6d6d6d6ddddddddddddddd76666661dd76666661dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd71111111dd71111111dddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__sfx__
000500002905026050210500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500001f05023050270500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
